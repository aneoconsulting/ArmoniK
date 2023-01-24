resource "kubernetes_secret" "redis_endpoints" {
  metadata {
    name      = "redis-endpoints"
    namespace = var.namespace
  }
  data = {
    host = local.redis_endpoints.ip
    port = local.redis_endpoints.port
    url  = local.redis_url
  }
}