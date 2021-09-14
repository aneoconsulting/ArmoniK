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
      version = "~> 3.55.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.4.1"
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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "template" {
}

provider "tls" {
}

provider "archive" {
}

provider "kubectl" {
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

provider "aws" {
  access_key                  = var.access_key
  region                      = var.region
  secret_key                  = var.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:${var.dynamodb_port}"
    lambda = "http://localhost:${var.local_services_port}"
    iam = "http://localhost:${var.local_services_port}"
    cloudwatch = "http://localhost:${var.local_services_port}"
    cloudwatchlogs = "http://localhost:${var.local_services_port}"
    cloudwatchevents = "http://localhost:${var.local_services_port}"
    apigateway = "http://localhost:${var.local_services_port}"
    sqs = "http://localhost:${var.local_services_port}"
  }
}

