# Envvars
locals {
  datasources_config = <<EOF
apiVersion: 1

datasources:
- name: Prometheus
  type: prometheus
  url: ${var.prometheus_url}
  access: proxy
  isDefault: true
  jsonData:
    httpMethod: 'POST'
EOF
}

# configmap with all the variables
resource "kubernetes_config_map" "datasources_config" {
  metadata {
    name      = "datasources-configmap"
    namespace = var.namespace
  }
  data = {
    "datasources.yml" = local.datasources_config
  }
}

resource "local_file" "datasources_config_file" {
  content  = local.datasources_config
  filename = "${path.root}/generated/configmaps/grafana/datasources-grafana.yml"
}