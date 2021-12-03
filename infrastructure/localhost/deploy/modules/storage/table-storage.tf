# In the local deployment:
# MongoDB is used as table storage
# MongoDB is deployed as a service in Kubernetes cluster

# Kubernetes MongoDB statefulset
resource "kubernetes_stateful_set" "mongodb" {
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
    service_name = "mongodb"
    replicas     = var.table_storage.replicas
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
            "--port=${var.table_storage.port}",
            "--bind_ip=0.0.0.0",
            "--replSet=rs0"
          ]
          port {
            container_port = var.table_storage.port
          }
          env {
            name  = "EDGE_PORT"
            value = var.table_storage.port
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
    name      = kubernetes_stateful_set.mongodb.metadata.0.name
    namespace = kubernetes_stateful_set.mongodb.metadata.0.namespace
    labels    = {
      app     = kubernetes_stateful_set.mongodb.metadata.0.labels.app
      type    = kubernetes_stateful_set.mongodb.metadata.0.labels.type
      service = kubernetes_stateful_set.mongodb.metadata.0.labels.service
    }
  }
  spec {
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_stateful_set.mongodb.metadata.0.labels.app
      type    = kubernetes_stateful_set.mongodb.metadata.0.labels.type
      service = kubernetes_stateful_set.mongodb.metadata.0.labels.service
    }
    port {
      port = var.table_storage.port
    }
  }
}

# Active replicas in MongoDB
resource "null_resource" "activate_replica_in_mongo" {
  depends_on = [kubernetes_service.mongodb]
  provisioner "local-exec" {
    command = "kubectl exec mongodb-0 -n ${var.namespace} -- mongo --eval 'rs.initiate()'"
  }
}
