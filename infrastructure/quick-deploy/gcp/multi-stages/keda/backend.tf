terraform {
  backend "gcs" {
    prefix = "keda-terraform.tfstate"
  }
}