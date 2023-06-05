terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.0.7"
    }
  }
}
