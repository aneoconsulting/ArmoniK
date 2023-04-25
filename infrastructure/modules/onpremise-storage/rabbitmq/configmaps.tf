locals {
  enabled_plugins = "[rabbitmq_management ,rabbitmq_management_agent ${local.plug}]."
}

# configmap with all the variables
resource "kubernetes_config_map" "rabbitmq_configs" {
  metadata {
    name      = "rabbitmq-configs"
    namespace = var.namespace
  }
  data = {
    "enabled_plugins" = local.enabled_plugins
  }
}

resource "local_file" "plugins" {
  content  = local.enabled_plugins
  filename = "${path.module}/generated/rabbitmq/plugins"
}