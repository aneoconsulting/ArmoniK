resource "kubernetes_secret" "activemq_endpoints" {
  metadata {
    name      = "activemq-endpoints"
    namespace = var.namespace
  }
  data = {
    host    = local.activemq_endpoints.ip
    port    = local.activemq_endpoints.port
    url     = local.activemq_url
    web_url = local.activemq_web_url
  }
}