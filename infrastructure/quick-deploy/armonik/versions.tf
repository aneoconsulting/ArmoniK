terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.2.0"
    }
  }
}