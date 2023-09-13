terraform {
  backend "gcs" {
    prefix = "vpc-terraform.tfstate"
  }
}