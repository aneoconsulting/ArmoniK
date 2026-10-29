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

# Custom resources of the MongoDB Percona module. Without this block, the provider would use the default
# kubeconfig of the machine running Terraform
provider "kubectl" {
  host             = "https://${module.gke.endpoint_dns}"
  token            = data.google_client_config.current.access_token
  load_config_file = false
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    host  = "https://${module.gke.endpoint_dns}"
    token = data.google_client_config.current.access_token
  }
}
