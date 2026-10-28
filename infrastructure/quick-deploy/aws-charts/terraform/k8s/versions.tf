terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59, < 7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1, < 4.0"
    }
  }
}
