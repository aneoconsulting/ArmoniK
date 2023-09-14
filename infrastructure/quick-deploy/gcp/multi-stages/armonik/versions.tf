terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.78.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
}