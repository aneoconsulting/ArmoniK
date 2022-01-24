terraform {
  required_providers {
    aws        = {
      source  = "hashicorp/aws"
      version = ">= 3.72.0"
    }
    random     = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    cloudinit  = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.2.0"
    }
    tls        = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0"
    }
  }
}