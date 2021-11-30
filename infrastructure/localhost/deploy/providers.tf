provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
}