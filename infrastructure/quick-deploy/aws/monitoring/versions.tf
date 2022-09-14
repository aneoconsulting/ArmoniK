terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
  }
}