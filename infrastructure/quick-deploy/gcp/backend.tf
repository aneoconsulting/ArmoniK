terraform {
  backend "gcs" {
    prefix = "armonik-terraform.tfstate"
  }
}