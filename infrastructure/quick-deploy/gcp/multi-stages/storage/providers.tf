# GCP provider
provider "google" {
  project = var.project
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${var.gke.endpoint}"
  cluster_ca_certificate = base64decode(var.gke.ca_certificate)
  token                  = data.google_client_config.current.access_token
  insecure               = false
}