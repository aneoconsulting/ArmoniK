resource "kubernetes_job" "partitions_in_database" {
  metadata {
    name      = "partitions-in-database"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "partitions-in-database"
      type    = "monitoring"
    }
  }
  spec {
    template {
      metadata {
        name = "partitions-in-database"
        labels = {
          app     = "armonik"
          service = "partitions-in-database"
          type    = "monitoring"
        }
      }
      spec {
        node_selector = local.job_partitions_in_database_node_selector
        dynamic "toleration" {
          for_each = (local.job_partitions_in_database_node_selector != {} ? [
            for index in range(0, length(local.job_partitions_in_database_node_selector_keys)) : {
              key   = local.job_partitions_in_database_node_selector_keys[index]
              value = local.job_partitions_in_database_node_selector_values[index]
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
          for_each = (var.job_partitions_in_database.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.job_partitions_in_database.image_pull_secrets
          }
        }
        restart_policy = "OnFailure" # Always, OnFailure, Never
        container {
          name              = var.job_partitions_in_database.name
          image             = var.job_partitions_in_database.tag != "" ? "${var.job_partitions_in_database.image}:${var.job_partitions_in_database.tag}" : var.job_partitions_in_database.image
          image_pull_policy = var.job_partitions_in_database.image_pull_policy
          command           = ["/bin/bash", "-c", local.script]
          dynamic "env" {
            for_each = local.database_credentials
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key      = env.value.key
                  name     = env.value.name
                  optional = false
                }
              }
            }
          }
          dynamic "volume_mount" {
            for_each = (local.mongodb_certificates_secret != "" ? [1] : [])
            content {
              name       = "mongodb-secret-volume"
              mount_path = "/mongodb"
              read_only  = true
            }
          }
        }
        dynamic "volume" {
          for_each = (local.mongodb_certificates_secret != "" ? [1] : [])
          content {
            name = "mongodb-secret-volume"
            secret {
              secret_name = local.mongodb_certificates_secret
              optional    = false
            }
          }
        }
      }
    }
    backoff_limit = 5
  }
  wait_for_completion = true
  timeouts {
    create = "2m"
    update = "2m"
  }
}

locals {
  script = <<EOF
#!/bin/bash
# Drop
mongosh --tlsCAFile ${local.mongodb_ca_filename} --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB_User --password $MongoDB_Password mongodb://$MongoDB_Host:$MongoDB_Port/database --eval 'db.PartitionData.drop()'

# Insert
mongosh --tlsCAFile ${local.mongodb_ca_filename} --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB_User --password $MongoDB_Password mongodb://$MongoDB_Host:$MongoDB_Port/database --eval 'db.PartitionData.insertMany(${jsonencode(local.partitions_data)})'
EOF
}

