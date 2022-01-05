terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6.1"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}