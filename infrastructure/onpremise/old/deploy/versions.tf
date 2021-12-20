terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }

    external = {
      source  = "hashicorp/external"
      version = ">= 2.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
  }
}