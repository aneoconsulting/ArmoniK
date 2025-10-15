terraform {
  required_version = ">= 1.13.4"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
  }
}
