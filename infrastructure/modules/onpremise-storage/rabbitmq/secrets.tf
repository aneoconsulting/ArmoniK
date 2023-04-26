resource "kubernetes_secret" "rabbitmq" {
  metadata {
    name      = "activemq"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = format("%s\n%s", tls_locally_signed_cert.rabbitmq_certificate.cert_pem, tls_self_signed_cert.root_rabbitmq.cert_pem)
    # username    = random_string.mq_application_user.result
    # password    = random_password.mq_application_password.result
    username    = "guest"
    password    = "guest"
    host        = local.rabbitmq_endpoints.ip
    port        = local.rabbitmq_endpoints.port
    url         = local.rabbitmq_url
    web_url     = local.rabbitmq_web_url
    protocol    = var.rabbitmq.protocol
  }
}
