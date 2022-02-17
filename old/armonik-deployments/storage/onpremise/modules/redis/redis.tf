# Redis is deployed as a service in Kubernetes create-cluster

resource "random_password" "redis_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "redis_user" {
  metadata {
    name      = var.redis.credentials_user_secret
    namespace = var.redis.credentials_user_namespace
  }

  data = {
    "${var.redis.credentials_user_key_username}" = ""
    "${var.redis.credentials_user_key_password}" = "${random_password.redis_password.result}"
  }

  type = var.redis.credentials_user_type
}

#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_redis" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_redis" {
  key_algorithm         = tls_private_key.root_redis.algorithm
  private_key_pem       = tls_private_key.root_redis.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]

  subject {
    organization = "ArmoniK Redis Root (NonTrusted)"
    common_name  = "ArmoniK Redis Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "redis_private_key" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "redis_cert_request" {
  key_algorithm   = tls_private_key.redis_private_key.algorithm
  private_key_pem = tls_private_key.redis_private_key.private_key_pem

  subject {
    country      = "France"
    common_name  = "127.0.0.1"
    # organization = "127.0.0.1"
  }
}

resource "tls_locally_signed_cert" "redis_certificate" {
  cert_request_pem   = tls_cert_request.redis_cert_request.cert_request_pem
  ca_key_algorithm   = tls_private_key.root_redis.algorithm
  ca_private_key_pem = tls_private_key.root_redis.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_redis.cert_pem

  validity_period_hours = "168"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

resource "kubernetes_secret" "redis_certificate" {
  metadata {
    name      = var.redis.certificates_server_secret
    namespace = var.namespace
  }

  data = {
    "root.pem" = "${tls_self_signed_cert.root_redis.cert_pem}"
    "cert.pem" = "${tls_locally_signed_cert.redis_certificate.cert_pem}"
    "key.pem" = "${tls_private_key.redis_private_key.private_key_pem}"
  }
}

resource "kubernetes_secret" "redis_certificate_client" {
  metadata {
    name      = var.redis.certificates_client_secret
    namespace = var.redis.certificates_client_namespace
  }

  data = {
    "chain.pem" = format("%s\n%s", tls_locally_signed_cert.redis_certificate.cert_pem, tls_self_signed_cert.root_redis.cert_pem)
  }
}

# Kubernetes Redis deployment
resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels    = {
      app     = "storage"
      type    = "object"
      service = "redis"
    }
  }
  spec {
    replicas = var.redis.replicas
    selector {
      match_labels = {
        app     = "storage"
        type    = "object"
        service = "redis"
      }
    }
    template {
      metadata {
        name   = "redis"
        labels = {
          app     = "storage"
          type    = "object"
          service = "redis"
        }
      }
      spec {
        node_selector = var.redis.node_selector
        container {
          name    = "redis"
          image   = "${var.redis.image}:${var.redis.tag}"
          command = ["redis-server"]
          args    = [
            "--tls-port ${var.redis.port}",
            "--port 0",
            "--tls-cert-file /certificates/cert.pem",
            "--tls-key-file /certificates/key.pem",
            "--tls-auth-clients no",
            "--requirepass ${random_password.redis_password.result}"
          ]
          port {
            container_port = var.redis.port
          }
          volume_mount {
            name       = "redis-storage-secret-volume"
            mount_path = "/certificates"
            read_only  = true
          }
        }
        volume {
          name = "redis-storage-secret-volume"
          secret {
            secret_name = kubernetes_secret.redis_certificate.metadata[0].name
            optional    = false
          }
        }
      }
    }
  }
}

# Kubernetes Redis service
resource "kubernetes_service" "redis" {
  metadata {
    name      = kubernetes_deployment.redis.metadata.0.name
    namespace = kubernetes_deployment.redis.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.redis.metadata.0.labels.app
      type    = kubernetes_deployment.redis.metadata.0.labels.type
      service = kubernetes_deployment.redis.metadata.0.labels.service
    }
  }
  spec {
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.redis.metadata.0.labels.app
      type    = kubernetes_deployment.redis.metadata.0.labels.type
      service = kubernetes_deployment.redis.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.redis.metadata.0.name
      port        = var.redis.port
      target_port = var.redis.port
      protocol    = "TCP"
    }
  }
}
