# K8s configuration
data "external" "k8s_config_context" {
  program     = ["bash", "k8s_config.sh"]
  working_dir = "./scripts"
}

# Object storage
module "storage" {
  source         = "./storage"
  namespace      = var.namespace
  object_storage = {
    replicas     = var.object_storage.replicas,
    port         = var.object_storage.port,
    certificates = {
      cert_file    = var.object_storage.certificates["cert_file"],
      key_file     = var.object_storage.certificates["key_file"],
      ca_cert_file = var.object_storage.certificates["ca_cert_file"]
    },
    secret       = var.object_storage.secret
  }
}