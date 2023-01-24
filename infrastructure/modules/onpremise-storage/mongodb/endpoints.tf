resource "kubernetes_secret" "mongodb_endpoints" {
  metadata {
    name      = "mongodb-endpoints"
    namespace = var.namespace
  }
  data = {
    host = local.mongodb_endpoints.ip
    port = local.mongodb_endpoints.port
    url  = local.mongodb_url
  }
}