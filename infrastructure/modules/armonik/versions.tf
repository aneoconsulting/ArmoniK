terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = ">= 0.0.7"
    }
  }
}
