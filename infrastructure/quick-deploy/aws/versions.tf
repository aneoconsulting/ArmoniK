terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72"
    }
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
      source  = "alekc/kubectl"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4.2"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.4.0"
    }
    skopeo2 = {
      source  = "bsquare-corp/skopeo2"
      version = "~> 1.3.0"
    }
  }
}
