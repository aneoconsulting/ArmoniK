// https://github.com/skydome/terraform-kubernetes-mongodb/blob/master/main.tf

resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name   = "mongodb"
    labels = {
      app     = "local-scheduler"
      service = "mongodb"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "local-scheduler"
        service = "mongodb"
      }
    }

    service_name = "mongodb"

    template {
      metadata {
        labels = {
          app     = "local-scheduler"
          service = "mongodb"
        }
      }

      spec {
        volume {
          name = "configdir"
        }

        volume {
          name = "datadir"
        }

        container {
          image   = "mongo:bionic"
          name    = "mongodb"
          command = ["mongod"]
          args    = [
            "--dbpath=/data/db",
            "--port=${var.mongodb_port}",
            "--bind_ip=0.0.0.0",
            #"--replSet=rs0"
          ]

          env {
            name  = "EDGE_PORT"
            value = var.mongodb_port
          }

          port {
            container_port = var.mongodb_port
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
      }
    }
  }
}

resource "kubernetes_service" "mongodb" {
  metadata {
    name = "mongodb"
  }

  spec {
    selector = {
      app     = kubernetes_stateful_set.mongodb.metadata.0.labels.app
      service = kubernetes_stateful_set.mongodb.metadata.0.labels.service
    }
    type     = "LoadBalancer"
    port {
      protocol = "TCP"
      port     = var.mongodb_port
      name     = "mongodb"
    }
  }
}
/*
resource "null_resource" "activate_replica_in_mongo" {
  depends_on = [kubernetes_stateful_set.mongodb]
  provisioner "local-exec" {
    command = "kubectl exec mongodb-0 -- mongo --eval 'rs.initiate()'"
  }
}
*/