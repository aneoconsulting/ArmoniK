terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.78.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}