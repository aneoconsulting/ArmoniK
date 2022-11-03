#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_ingress" {
  count       = (var.ingress != null ? var.ingress.tls : false) ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_ingress" {
  count                 = length(tls_private_key.root_ingress)
  key_algorithm         = tls_private_key.root_ingress.0.algorithm
  private_key_pem       = tls_private_key.root_ingress.0.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"
  allowed_uses = [
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
# Client Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "client_root_ingress" {
  count       = (var.ingress != null ? var.ingress.mtls : false) ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "client_root_ingress" {
  count                 = length(tls_private_key.client_root_ingress)
  key_algorithm         = tls_private_key.client_root_ingress.0.algorithm
  private_key_pem       = tls_private_key.client_root_ingress.0.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
  subject {
    organization = "ArmoniK Client Ingress Root (NonTrusted)"
    common_name  = "ArmoniK Client Ingress Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Server Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "ingress_private_key" {
  count       = length(tls_private_key.root_ingress)
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "ingress_cert_request" {
  count           = length(tls_private_key.ingress_private_key)
  key_algorithm   = tls_private_key.ingress_private_key.0.algorithm
  private_key_pem = tls_private_key.ingress_private_key.0.private_key_pem
  subject {
    country     = "France"
    common_name = "127.0.0.1"
    # organization = "127.0.0.1"
  }
}

resource "tls_locally_signed_cert" "ingress_certificate" {
  count                 = length(tls_cert_request.ingress_cert_request)
  cert_request_pem      = tls_cert_request.ingress_cert_request.0.cert_request_pem
  ca_key_algorithm      = tls_private_key.root_ingress.0.algorithm
  ca_private_key_pem    = tls_private_key.root_ingress.0.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root_ingress.0.cert_pem
  validity_period_hours = "168"
  allowed_uses = [
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
  data = length(tls_locally_signed_cert.ingress_certificate) > 0 ? {
    "ingress.pem" = format("%s\n%s", tls_locally_signed_cert.ingress_certificate.0.cert_pem, tls_private_key.ingress_private_key.0.private_key_pem)
    "ingress.crt" = tls_locally_signed_cert.ingress_certificate.0.cert_pem
    "ingress.key" = tls_private_key.ingress_private_key.0.private_key_pem
  } : {}
}

#------------------------------------------------------------------------------
# Client Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "ingress_client_private_key" {
  count       = (var.ingress != null ? var.ingress.mtls && var.ingress.generate_client_cert : false) ? length(tls_private_key.client_root_ingress)*length(local.ingress_generated_cert.names): 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "random_string" "common_name" {
  count   = length(tls_private_key.ingress_client_private_key)
  length  = 16
  special = false
  number  = false
}

resource "tls_cert_request" "ingress_client_cert_request" {
  count           = length(tls_private_key.ingress_client_private_key)
  key_algorithm   = tls_private_key.ingress_client_private_key[count.index].algorithm
  private_key_pem = tls_private_key.ingress_client_private_key[count.index].private_key_pem
  subject {
    country     = "France"
    common_name = random_string.common_name[count.index].result
    # organization = "127.0.0.1"
  }
}

resource "tls_locally_signed_cert" "ingress_client_certificate" {
  count                 = length(tls_cert_request.ingress_client_cert_request)
  cert_request_pem      = tls_cert_request.ingress_client_cert_request[count.index].cert_request_pem
  ca_key_algorithm      = tls_private_key.client_root_ingress.0.algorithm
  ca_private_key_pem    = tls_private_key.client_root_ingress.0.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.client_root_ingress.0.cert_pem
  validity_period_hours = "168"
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

resource "kubernetes_secret" "ingress_client_certificate" {
  metadata {
    name      = "ingress-user-certificates"
    namespace = var.namespace
  }
  data = length(tls_locally_signed_cert.ingress_client_certificate) > 0 ? {
    "ca.pem"     = tls_self_signed_cert.client_root_ingress.0.cert_pem
  } : {}
}

resource "local_sensitive_file" "ingress_ca" {
  count           = length(tls_self_signed_cert.root_ingress)
  content         = tls_self_signed_cert.root_ingress.0.cert_pem
  filename        = "${path.root}/generated/certificates/ingress/ca.crt"
  file_permission = "0600"
}

resource "local_sensitive_file" "ingress_client_crt" {
  count           = length(tls_locally_signed_cert.ingress_client_certificate)
  content         = tls_locally_signed_cert.ingress_client_certificate[count.index].cert_pem
  filename        = "${path.root}/generated/certificates/ingress/client.${local.ingress_generated_cert.names[count.index]}.crt"
  file_permission = "0600"
}

resource "local_sensitive_file" "ingress_client_key" {
  count           = length(tls_private_key.ingress_client_private_key)
  content         = tls_private_key.ingress_client_private_key[count.index].private_key_pem
  filename        = "${path.root}/generated/certificates/ingress/client.${local.ingress_generated_cert.names[count.index]}.key"
  file_permission = "0600"
}
