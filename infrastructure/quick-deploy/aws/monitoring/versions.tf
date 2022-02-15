terraform {
  required_providers {
    aws    = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    external    = {
      source  = "hashicorp/external"
      version = "~> 2.2.0"
    }
    kubernetes    = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.8.0"
    }
    local    = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
  }
}