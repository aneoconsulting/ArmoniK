terraform {
  required_providers {
    aws    = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    null   = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
  }
}