terraform {
  # Write-only secret of the registry credentials (secret_string_wo)
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59, < 7.0"
    }
    # The eks module of ArmoniK.Infra pins helm below 3
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38, < 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
  }
}
