# K8s configuration
data "external" "k8s_config_context" {
  program     = ["bash", "k8s_config.sh"]
  working_dir = "../utils/scripts"
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
}

provider "aws" {
  region                  = var.aws_region
  #shared_credentials_file = pathexpand(".aws/credentials")
  #profile                 = var.aws_profile
}