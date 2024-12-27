terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.78.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.1"
    }
    generic = {
      source  = "aneoconsulting.github.io/aneoconsulting/generic"
      version = "~> 0.1.2"
    }
  }
}

