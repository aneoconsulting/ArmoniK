resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
    username    = random_string.mongodb_application_user.result
    password    = random_password.mongodb_application_password.result
    host        = local.mongodb_dns
    port        = local.mongodb_port
    url         = local.mongodb_url
  }
}