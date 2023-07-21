# K8s configuration
data "external" "k8s_config_context" {
  program     = ["bash", "k8s_config.sh", var.k8s_config_path]
  working_dir = ".${path.root}/scripts"
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
}