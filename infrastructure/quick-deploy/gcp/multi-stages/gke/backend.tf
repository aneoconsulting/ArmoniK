terraform {
  backend "gcs" {
    prefix = "gke-terraform.tfstate"
  }
}