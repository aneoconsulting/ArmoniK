terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.1"
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
      version = "~> 4.2.1"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.2.5"
    }
    // Workaround for https://github.com/bsquare-corp/terraform-provider-skopeo2/issues/95
    skopeo2 = {
      source  = "bsquare-corp/skopeo2"
      version = ">= 1.2.0, < 1.3.0"
    }
  }
}
