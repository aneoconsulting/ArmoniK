# MongoDB is deployed as a service in Kubernetes create-cluster

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
            value = "tmpAdmin"
          }
          env {
            name  = "MONGO_INITDB_ROOT_PASSWORD"
            value = "tmpPassword"
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
            secret_name = var.mongodb.secret
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
