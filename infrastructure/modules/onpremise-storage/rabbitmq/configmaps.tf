locals {
  enabled_plugins = "[rabbitmq_management, rabbitmq_management_agent, rabbitmq_amqp1_0]."
}

# configmap with all the variables
resource "kubernetes_config_map" "rabbitmq_plugins" {
  metadata {
    name      = "rabbitmq-plugins"
    namespace = var.namespace
  }
  data = {
    "enabled_plugins" = local.enabled_plugins
  }
}