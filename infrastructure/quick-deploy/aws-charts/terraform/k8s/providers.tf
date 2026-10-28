# The cluster and everything around it come from terraform/aws
data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = var.bucket
    region = var.region
    key    = "armonik-quick-deploy/aws.tfstate"
  }
}

locals {
  aws = data.terraform_remote_state.aws.outputs.k8s
}

provider "aws" {
  region  = local.aws.region
  profile = var.profile
}

# Pulls the OCI charts through the ECR pull-through cache. The token lasts 12 hours and is read at every
# plan; being provider configuration, it never reaches the state.
data "aws_ecr_authorization_token" "this" {}

provider "helm" {
  kubernetes = {
    host                   = local.aws.endpoint
    cluster_ca_certificate = base64decode(local.aws.ca_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = concat(
        ["eks", "get-token", "--cluster-name", local.aws.cluster_name, "--region", local.aws.region],
        var.profile == null ? [] : ["--profile", var.profile],
      )
    }
  }

  registries = [{
    url      = "oci://${local.aws.registry}"
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }]
}
