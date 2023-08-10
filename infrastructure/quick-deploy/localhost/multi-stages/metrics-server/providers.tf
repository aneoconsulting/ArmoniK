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