terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 8.9"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 3.0"
    }
  }
}
