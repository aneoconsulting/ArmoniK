provider "google" {
  project = var.project
  region  = var.region
}

# Service identity of the Artifact Registry module
provider "google-beta" {
  project = var.project
  region  = var.region
}

# Access token of the caller, read at every plan; being provider configuration, it never reaches the state
data "google_client_config" "current" {}

# One stack: the cluster is created by this same apply, so its endpoint is unknown on the first plan. The providers
# below accept that and only connect during the apply. A change that replaces the cluster makes them unknown again,
# with the cluster resources still in the state: destroy the whole stack instead (README).
#
# The DNS endpoint of the control plane is authenticated by IAM and serves a publicly trusted certificate: no CA.
provider "kubernetes" {
  host  = "https://${module.gke.endpoint_dns}"
  token = data.google_client_config.current.access_token
}

# ComputeClasses (kubectl_manifest): kubernetes_manifest reads the cluster at plan time, which does not exist yet.
# lazy_load builds the client only when a resource needs it, during the apply; load_config_file = false keeps the
# local kubeconfig out of it.
provider "kubectl" {
  host             = "https://${module.gke.endpoint_dns}"
  token            = data.google_client_config.current.access_token
  load_config_file = false
  lazy_load        = true
}

# The charts are pulled at plan time, before any repository of this stack exists: straight from Docker Hub, with the
# Docker Hub token when one is given. The images go through the pull-through caches (registry.tf).
provider "helm" {
  kubernetes {
    host  = "https://${module.gke.endpoint_dns}"
    token = data.google_client_config.current.access_token
  }

  dynamic "registry" {
    for_each = local.dockerhub_login
    content {
      url      = "oci://registry-1.docker.io"
      username = registry.value.username
      password = registry.value.token
    }
  }
}
