# MongoDB is deployed as a service in Kubernetes create-cluster

#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_mongodb" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_mongodb" {
  key_algorithm         = tls_private_key.root_mongodb.algorithm
  private_key_pem       = tls_private_key.root_mongodb.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]

  subject {
    organization = "ArmoniK mongodb Root (NonTrusted)"
    common_name  = "ArmoniK mongodb Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "mongodb_private_key" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "mongodb_cert_request" {
  key_algorithm   = tls_private_key.mongodb_private_key.algorithm
  private_key_pem = tls_private_key.mongodb_private_key.private_key_pem

  subject {
    country      = "France"
    common_name  = "127.0.0.1"
    # organization = "127.0.0.1"
  }
}

resource "tls_locally_signed_cert" "mongodb_certificate" {
  cert_request_pem   = tls_cert_request.mongodb_cert_request.cert_request_pem
  ca_key_algorithm   = tls_private_key.root_mongodb.algorithm
  ca_private_key_pem = tls_private_key.root_mongodb.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_mongodb.cert_pem

  validity_period_hours = "168"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

resource "kubernetes_secret" "mongodb_certificate" {
  metadata {
    name      = var.mongodb.certificates_server_secret
    namespace = var.namespace
  }

  data = {
    "mongodb.pem" = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_private_key.mongodb_private_key.private_key_pem)
  }
}

resource "kubernetes_secret" "mongodb_certificate_client" {
  metadata {
    name      = var.mongodb.certificates_client_secret
    namespace = var.mongodb.certificates_client_namespace
  }

  data = {
    "chain.pem" = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
  }
}

# Kubernetes MongoDB deployment
resource "kubernetes_deployment" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
    labels    = {
      app     = "storage"
      type    = "table"
      service = "mongodb"
    }
  }
  spec {
    replicas = var.mongodb.replicas
    selector {
      match_labels = {
        app     = "storage"
        type    = "table"
        service = "mongodb"
      }
    }
    template {
      metadata {
        name   = "mongodb"
        labels = {
          app     = "storage"
          type    = "table"
          service = "mongodb"
        }
      }
      spec {
        node_selector = var.mongodb.node_selector
        container {
          name  = "mongodb"
          image = "${var.mongodb.image}:${var.mongodb.tag}"
          # command = ["mongod"]
          args  = [
            "--dbpath=/data/db",
            "--port=${var.mongodb.port}",
            "--bind_ip=0.0.0.0",
            "--tlsMode=requireTLS",
            "--tlsDisabledProtocols=TLS1_0",
            "--tlsCertificateKeyFile=/mongodb/mongodb.pem",
            "--auth",
          ]
          # command = ["cat", "/mongodb/mongodb.pem"]
          port {
            name           = "mongodb"
            container_port = var.mongodb.port
          }
          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = random_string.mongodb_admin_user.result
          }
          env {
            name  = "MONGO_INITDB_ROOT_PASSWORD"
            value = random_password.mongodb_admin_password.result
          }
          volume_mount {
            name       = "mongodb-secret-volume"
            mount_path = "/mongodb/"
            read_only  = true
          }
          volume_mount {
            name       = "init-files"
            mount_path = "/docker-entrypoint-initdb.d/"
          }
        }
        volume {
          name = "init-files"
          config_map {
            name     = kubernetes_config_map.init_mongodb_js.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "mongodb-secret-volume"
          secret {
            secret_name = kubernetes_secret.mongodb_certificate.metadata[0].name
            optional    = false
          }
        }
      }
    }
  }
}

# Kubernetes MongoDB service
resource "kubernetes_service" "mongodb" {
  metadata {
    name      = kubernetes_deployment.mongodb.metadata.0.name
    namespace = kubernetes_deployment.mongodb.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.mongodb.metadata.0.labels.app
      type    = kubernetes_deployment.mongodb.metadata.0.labels.type
      service = kubernetes_deployment.mongodb.metadata.0.labels.service
    }
  }
  spec {
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.mongodb.metadata.0.labels.app
      type    = kubernetes_deployment.mongodb.metadata.0.labels.type
      service = kubernetes_deployment.mongodb.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.mongodb.metadata.0.name
      port        = var.mongodb.port
      target_port = var.mongodb.port
      protocol    = "TCP"
    }
  }
}
