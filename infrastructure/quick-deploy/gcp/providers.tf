# GCP provider
provider "google" {
  project = var.project
  region  = var.region
}

# Service identity of the Memorystore module
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

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    host  = "https://${module.gke.endpoint_dns}"
    token = data.google_client_config.current.access_token
  }
}
