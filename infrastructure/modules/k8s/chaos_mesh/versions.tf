terraform {
  required_version = ">= 1.16.5"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
  }
}
