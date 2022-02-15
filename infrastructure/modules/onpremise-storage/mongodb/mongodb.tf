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
    replicas = 1
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
        dynamic toleration {
          for_each = (var.mongodb.node_selector != {} ? [1] : [])
          content {
            key      = keys(var.mongodb.node_selector)[0]
            operator = "Equal"
            value    = values(var.mongodb.node_selector)[0]
            effect   = "NoSchedule"
          }
        }
        container {
          name  = "mongodb"
          image = "${var.mongodb.image}:${var.mongodb.tag}"
          args  = [
            "--dbpath=/data/db",
            "--port=27017",
            "--bind_ip=0.0.0.0",
            "--tlsMode=requireTLS",
            "--tlsDisabledProtocols=TLS1_0",
            "--tlsCertificateKeyFile=/mongodb/mongodb.pem",
            "--auth",
          ]
          port {
            name           = "mongodb"
            container_port = 27017
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
            name     = kubernetes_config_map.mongodb_js.metadata.0.name
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
      port        = 27017
      target_port = 27017
      protocol    = "TCP"
    }
  }
}
