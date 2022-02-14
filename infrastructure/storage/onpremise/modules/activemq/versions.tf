terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
    pkcs12 = {
      source = "chilicat/pkcs12"
      version = "0.0.7"
    }
  }
}