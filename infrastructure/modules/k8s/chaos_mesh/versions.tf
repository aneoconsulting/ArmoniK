terraform {
  required_version = ">= 1.17.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
  }
}
