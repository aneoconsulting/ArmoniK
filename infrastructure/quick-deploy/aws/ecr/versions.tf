terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}