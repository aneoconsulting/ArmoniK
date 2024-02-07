terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }
  }
}
