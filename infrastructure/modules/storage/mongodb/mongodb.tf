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
    replicas     = var.mongodb.replicas
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
          name    = "mongodb"
          image   = "mongo:bionic"
          command = ["mongod"]
          args    = [
            "--dbpath=/data/db",
            "--port=${var.mongodb.port}",
            "--bind_ip=0.0.0.0",
            "--replSet=rs0"
          ]
          port {
            container_port = var.mongodb.port
          }
          env {
            name  = "EDGE_PORT"
            value = var.mongodb.port
          }
          volume_mount {
            name       = "configdir"
            mount_path = "/data/configdb"
          }
          volume_mount {
            name       = "datadir"
            mount_path = "/data/db"
          }
        }
        volume {
          name = "configdir"
        }
        volume {
          name = "datadir"
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
    type     = "LoadBalancer"
    selector = {
      app     = kubernetes_deployment.mongodb.metadata.0.labels.app
      type    = kubernetes_deployment.mongodb.metadata.0.labels.type
      service = kubernetes_deployment.mongodb.metadata.0.labels.service
    }
    port {
      port = var.mongodb.port
    }
  }
}

# Active replicas in MongoDB
resource "null_resource" "activate_replica_in_mongo" {
  depends_on = [kubernetes_service.mongodb]
  provisioner "local-exec" {
    command = "kubectl exec svc/${kubernetes_service.mongodb.metadata.0.name} -n ${var.namespace} -- mongo --eval 'rs.initiate()'"
  }
}
