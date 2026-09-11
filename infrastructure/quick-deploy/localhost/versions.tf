terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4.1"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.4.0"
    }
  }
}
