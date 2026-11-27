provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = local.tags
  }
}

# The cluster endpoint of the eks module is known once its access policies are in effect
locals {
  kube_host = module.eks.cluster_endpoint
  kube_ca   = base64decode(module.eks.cluster_certificate_authority_data)
  kube_token_args = concat(
    ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region],
    var.profile == null ? [] : ["--profile", var.profile],
  )
}

provider "kubernetes" {
  host                   = local.kube_host
  cluster_ca_certificate = local.kube_ca
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = local.kube_token_args
  }
}

provider "helm" {
  kubernetes {
    host                   = local.kube_host
    cluster_ca_certificate = local.kube_ca
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = local.kube_token_args
    }
  }
}
