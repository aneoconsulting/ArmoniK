locals {
  logging_level_routing = var.logging_level == "Information" ? "Warning" : var.logging_level
}
# configmap with all the environment variables to set loglevels
resource "kubernetes_config_map" "log_config" {
  metadata {
    name      = "log-configmap"
    namespace = var.namespace
  }
  data = {
    "Serilog__MinimumLevel" : var.logging_level,
    "Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Hosting.Diagnostics" : local.logging_level_routing,
    "Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Routing.EndpointMiddleware" : local.logging_level_routing,
  }
}
