# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
  
  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1.0"
    }

    null= {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }

    kubernetes= {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6.1"
    }

    http= {
      source  = "terraform-aws-modules/http"
      version = "~> 2.4.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.3.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.1.0"
    }
  }
}

provider "aws" {
  region  = var.region
  default_tags {
    tags = {
      ArmonikTag = "armonik-${local.project_name}"
    }
  }
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


