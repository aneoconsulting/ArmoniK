#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_activemq" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_activemq" {
  private_key_pem       = tls_private_key.root_activemq.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"
  allowed_uses          = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
  subject {
    organization = "ArmoniK activemq Root (NonTrusted)"
    common_name  = "ArmoniK activemq Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "activemq_private_key" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "activemq_cert_request" {
  key_algorithm   = tls_private_key.activemq_private_key.algorithm
  private_key_pem = tls_private_key.activemq_private_key.private_key_pem
  subject {
    country     = "France"
    common_name = "127.0.0.1"
    # organization = "127.0.0.1"
  }
}

resource "tls_locally_signed_cert" "activemq_certificate" {
  cert_request_pem   = tls_cert_request.activemq_cert_request.cert_request_pem
  ca_key_algorithm   = tls_private_key.root_activemq.algorithm
  ca_private_key_pem = tls_private_key.root_activemq.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_activemq.cert_pem

  validity_period_hours = "168"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

resource "pkcs12_from_pem" "activemq_certificate" {
  password        = random_password.mq_keystore_password.result
  cert_pem        = tls_locally_signed_cert.activemq_certificate.cert_pem
  private_key_pem = tls_private_key.activemq_private_key.private_key_pem
  ca_pem          = tls_self_signed_cert.root_activemq.cert_pem
}

resource "kubernetes_secret" "activemq_certificate" {
  metadata {
    name      = "activemq-server-certificates"
    namespace = var.namespace
  }
  data        = {
    "root.pem" = tls_self_signed_cert.root_activemq.cert_pem
    "cert.pem" = tls_locally_signed_cert.activemq_certificate.cert_pem
    "key.pem"  = tls_private_key.activemq_private_key.private_key_pem
  }
  binary_data = {
    "certificate.pfx" = pkcs12_from_pem.activemq_certificate.result
  }
}

resource "kubernetes_secret" "activemq_client_certificate" {
  metadata {
    name      = "activemq-user-certificates"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = format("%s\n%s", tls_locally_signed_cert.activemq_certificate.cert_pem, tls_self_signed_cert.root_activemq.cert_pem)
  }
}

resource "local_sensitive_file" "activemq_client_certificate" {
  content           = format("%s\n%s", tls_locally_signed_cert.activemq_certificate.cert_pem, tls_self_signed_cert.root_activemq.cert_pem)
  filename        = "${path.root}/generated/certificates/activemq/chain.pem"
  file_permission = "0600"
}

