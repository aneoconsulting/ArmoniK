#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_ingress" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_ingress" {
  key_algorithm         = tls_private_key.root_ingress.algorithm
  private_key_pem       = tls_private_key.root_ingress.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"
  allowed_uses          = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
  subject {
    organization = "ArmoniK Ingress Root (NonTrusted)"
    common_name  = "ArmoniK Ingress Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "ingress_private_key" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "ingress_cert_request" {
  key_algorithm   = tls_private_key.ingress_private_key.algorithm
  private_key_pem = tls_private_key.ingress_private_key.private_key_pem
  subject {
    country     = "France"
    common_name = "127.0.0.1"
    # organization = "127.0.0.1"
  }
}

resource "tls_locally_signed_cert" "ingress_certificate" {
  cert_request_pem      = tls_cert_request.ingress_cert_request.cert_request_pem
  ca_key_algorithm      = tls_private_key.root_ingress.algorithm
  ca_private_key_pem    = tls_private_key.root_ingress.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root_ingress.cert_pem
  validity_period_hours = "168"
  allowed_uses          = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

resource "kubernetes_secret" "ingress_certificate" {
  metadata {
    name      = "ingress-server-certificates"
    namespace = var.namespace
  }
  data = {
    "ingress.pem" = format("%s\n%s", tls_locally_signed_cert.ingress_certificate.cert_pem, tls_private_key.ingress_private_key.private_key_pem)
  }
}

resource "kubernetes_secret" "ingress_client_certificate" {
  metadata {
    name      = "ingress-user-certificates"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = format("%s\n%s", tls_locally_signed_cert.ingress_certificate.cert_pem, tls_self_signed_cert.root_ingress.cert_pem)
  }
}
