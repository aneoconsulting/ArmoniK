terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = ">= 2.1.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.73.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}