# Kubernetes MongoDB deployment
resource "kubernetes_deployment" "mongodb" {
  for_each = local.replicas
  metadata {
    name      = "mongodb-${each.key}"
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "table"
      service = "mongodb-${each.key}"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "storage"
        type    = "table"
        service = "mongodb-${each.key}"
      }
    }
    template {
      metadata {
        name = "mongodb"
        labels = {
          app     = "storage"
          type    = "table"
          service = "mongodb-${each.key}"
        }
      }
      spec {
        node_selector = var.mongodb.node_selector
        dynamic "toleration" {
          for_each = (var.mongodb.node_selector != {} ? [
            for index in range(0, length(local.node_selector_keys)) : {
              key   = local.node_selector_keys[index]
              value = local.node_selector_values[index]
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.mongodb.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.mongodb.image_pull_secrets
          }
        }
        security_context {
          run_as_user = 999
          fs_group    = 999
        }
        container {
          name              = "mongodb"
          image             = "${var.mongodb.image}:${var.mongodb.tag}"
          image_pull_policy = "IfNotPresent"
          command           = ["/bin/bash"]
          args              = ["/start/mongostart.sh", "${each.key}"]
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
            name       = "mongodb-cluster-volume"
            mount_path = "/cluster/"
            read_only  = true
          }
          volume_mount {
            name       = "init-files"
            mount_path = "/docker-entrypoint-initdb.d/"
          }
          volume_mount {
            name       = "start-files"
            mount_path = "/start/"
          }
          dynamic "volume_mount" {
            for_each = (var.persistent_volume != null && var.persistent_volume != "" ? [1] : [])
            content {
              name       = "database"
              mount_path = "/data/db"
            }
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
          name = "start-files"
          config_map {
            name     = kubernetes_config_map.mongo_start_sh.metadata.0.name
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
        volume {
          name = "mongodb-cluster-volume"
          secret {
            secret_name = kubernetes_secret.mongodb_cluster.metadata[0].name
            optional    = false
          }
        }
        dynamic "volume" {
          for_each = (var.persistent_volume != null && var.persistent_volume != "" ? [1] : [])
          content {
            name = "database"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.mongodb.0.metadata.0.name
            }
          }
        }
      }
    }
  }
}

# Kubernetes MongoDB service
resource "kubernetes_service" "mongodb" {
  for_each = local.replicas
  metadata {
    name      = "mongodb-${each.key}"
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "table"
      service = "mongodb"
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app     = "storage"
      type    = "table"
      service = "mongodb-${each.key}"
    }
    port {
      name        = "mongodb"
      port        = 27017
      target_port = 27017
      protocol    = "TCP"
    }
  }
}

