resource "kubernetes_secret" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = format("%s\n%s", tls_locally_signed_cert.redis_certificate.cert_pem, tls_self_signed_cert.root_redis.cert_pem)
    username    = ""
    password    = random_password.redis_password.result
    host        = local.redis_endpoints.ip
    port        = local.redis_endpoints.port
    url         = local.redis_url
  }
}