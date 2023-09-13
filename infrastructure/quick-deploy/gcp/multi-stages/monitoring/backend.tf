terraform {
  backend "gcs" {
    prefix = "monitoring-terraform.tfstate"
  }
}