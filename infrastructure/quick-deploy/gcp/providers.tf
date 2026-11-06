# GCP provider
provider "google" {
  project = var.project
  region  = var.region
}

# Service identities of the Artifact Registry and Memorystore modules
provider "google-beta" {
  project = var.project
  region  = var.region
}

# The DNS endpoint of the control plane is reachable from anywhere when allowed, authenticated by IAM, and
# serves a publicly trusted certificate
provider "kubernetes" {
  host  = "https://${module.gke.endpoint_dns}"
  token = data.google_client_config.current.access_token
}

# Custom resources of the MongoDB Percona module (kubectl_manifest). Without this block, the provider falls
# back to the default kubeconfig of the machine running Terraform ($KUBECONFIG or ~/.kube/config): the plan
# fails when there is none, and the resources go to its current context, not necessarily this cluster,
# when there is one. load_config_file = false makes it use only the cluster below.
# On a new deployment, the cluster endpoint is unknown at plan time and the provider refuses to start without a
# host: lazy_load (alekc/kubectl >= 2.4.0) only builds the client when a resource needs it, during the apply
provider "kubectl" {
  host             = "https://${module.gke.endpoint_dns}"
  token            = data.google_client_config.current.access_token
  load_config_file = false
  lazy_load        = true
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    host  = "https://${module.gke.endpoint_dns}"
    token = data.google_client_config.current.access_token
  }
}
