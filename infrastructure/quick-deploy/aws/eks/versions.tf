terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.0"
    }
  }
}
