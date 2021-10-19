# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.5.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.13.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = var.k8s_config_context
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    config_path    = var.k8s_config_path
    config_context = var.k8s_config_context
  }
}