# The cluster and everything around it come from terraform/gcp
data "terraform_remote_state" "gcp" {
  backend = "gcs"
  config = {
    bucket = var.bucket
    prefix = "armonik-quick-deploy/gcp"
  }
}

locals {
  gcp = data.terraform_remote_state.gcp.outputs.k8s
}

provider "google" {
  project = local.gcp.project
}

# Access token of the caller, read at every plan; being provider configuration, it never reaches the state
data "google_client_config" "current" {}

# DNS endpoint of the control plane: authenticated by IAM, served with a publicly trusted certificate, so no CA
provider "helm" {
  kubernetes = {
    host  = "https://${local.gcp.endpoint_dns}"
    token = data.google_client_config.current.access_token
  }
}

provider "kubernetes" {
  host  = "https://${local.gcp.endpoint_dns}"
  token = data.google_client_config.current.access_token
}
