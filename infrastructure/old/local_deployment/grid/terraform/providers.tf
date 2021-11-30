terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6.1"
    }
    helm       = {
      source  = "hashicorp/helm"
      version = "~> 2.3.0"
    }
    kubectl    = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.13.0"
    }
    local      = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
    null       = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    random     = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    config_path    = var.k8s_config_path
    config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
  }
}