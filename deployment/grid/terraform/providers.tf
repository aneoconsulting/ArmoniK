# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.46.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = "2.2.0"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
  }
}


provider "template" {
}

provider "tls" {

}

provider "aws" {
  region  = var.region
}

provider "archive" {
}

provider "kubernetes" {
  host                   = module.compute_plane.cluster_endpoint
  cluster_ca_certificate = base64decode(module.compute_plane.certificate_authority.0.data)
  token                  = module.compute_plane.token
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    host                   = module.compute_plane.cluster_endpoint
    cluster_ca_certificate = base64decode(module.compute_plane.certificate_authority.0.data)
    token                  = module.compute_plane.token
  }
}


