terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1.0"
    }
  }
}