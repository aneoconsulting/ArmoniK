locals {
  # nonsensitive: which accounts are set is not a secret, the tokens stay sensitive
  registry_accounts = toset([for name, account in nonsensitive(var.registry_credentials) : name if account != null])

  # Login of the helm provider (providers.tf) on Docker Hub, at most one
  dockerhub_login = contains(local.registry_accounts, "dockerhub") ? [var.registry_credentials.dockerhub] : []

  # Pull-through cache of each upstream of the images of the charts. The fluent-bit image comes from Docker Hub
  # (fluent/fluent-bit) rather than cr.fluentbit.io, one upstream less.
  upstreams = {
    dockerhub = { docker_hub = true, uri = null }
    ghcr      = { docker_hub = false, uri = "https://ghcr.io" }
    quay      = { docker_hub = false, uri = "https://quay.io" }
    k8s       = { docker_hub = false, uri = "https://registry.k8s.io" }
  }
}

# Upstream tokens, read by the pull-through caches. secret_data_wo is write-only: the token never reaches the state.
resource "google_secret_manager_secret" "registry" {
  for_each  = local.registry_accounts
  secret_id = "${var.prefix}-registry-${each.key}"
  labels    = local.labels
  replication {
    auto {}
  }

  depends_on = [terraform_data.apis]
}

resource "google_secret_manager_secret_version" "registry" {
  for_each               = local.registry_accounts
  secret                 = google_secret_manager_secret.registry[each.key].id
  secret_data_wo         = var.registry_credentials[each.key].token
  secret_data_wo_version = var.registry_credentials_version
}

# The nodes read them through the project-wide Artifact Registry reader role of the gke module
# (grant_registry_access), which the worker images of var.partitions in this project's registries need anyway.
module "registry" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//container-registry/gcp/artifact-registry-remote?ref=dw/gcp-charts-deploy"

  name     = var.prefix
  location = var.region
  repositories = {
    for name, upstream in local.upstreams : name => merge(upstream, {
      credentials = contains(local.registry_accounts, name) ? {
        username                = nonsensitive(var.registry_credentials[name].username)
        password_secret_version = google_secret_manager_secret_version.registry[name].name
      } : null
    })
  }
  # Cached images unused for 30 days go away; the next pull fetches them again
  cleanup_older_than = "2592000s"
  labels             = local.labels

  depends_on = [terraform_data.apis]
}

# Images built here rather than pulled from an upstream: test workers that no CI publishes (the graph worker of Core
# PR #1334). <region>-docker.pkg.dev/<project>/<prefix>-images/<image>:<tag>, pushed by hand (podman push); the nodes
# read it through the same project-wide reader role as the caches.
resource "google_artifact_registry_repository" "images" {
  project       = var.project
  location      = var.region
  repository_id = "${var.prefix}-images"
  description   = "Images built for this deployment"
  format        = "DOCKER"
  labels        = local.labels

  docker_config {
    immutable_tags = true
  }

  depends_on = [terraform_data.apis]
}
