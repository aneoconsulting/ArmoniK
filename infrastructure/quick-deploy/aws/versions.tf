terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.62.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.2.5"
    }
  }
}
