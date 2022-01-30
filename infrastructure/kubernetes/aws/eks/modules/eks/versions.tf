terraform {
  required_providers {
    aws   = {
      source  = "hashicorp/aws"
      version = ">= 3.72.0"
    }
    helm  = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.4.0"
    }
    null  = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}