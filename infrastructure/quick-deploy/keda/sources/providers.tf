# K8s configuration
data "external" "k8s_config_context" {
  program     = ["bash", "k8s_config.sh"]
  working_dir = ".${path.root}/../../utils/scripts"
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    config_path    = var.k8s_config_path
    config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
  }
}