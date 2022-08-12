resource "kubernetes_pod" "partitions_in_database" {
  depends_on = [local_file.script]
  metadata {
    name      = "partitions-in-database"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "partitions-in-database"
      type    = "monitoring"
    }
  }
  spec {
    node_selector  = local.pod_partitions_in_database_node_selector
    dynamic toleration {
      for_each = (local.pod_partitions_in_database_node_selector != {} ? [
      for index in range(0, length(local.pod_partitions_in_database_node_selector_keys)) : {
        key   = local.pod_partitions_in_database_node_selector_keys[index]
        value = local.pod_partitions_in_database_node_selector_values[index]
      }
      ] : [])
      content {
        key      = toleration.value.key
        operator = "Equal"
        value    = toleration.value.value
        effect   = "NoSchedule"
      }
    }
    dynamic image_pull_secrets {
      for_each = (var.pod_partitions_in_database.image_pull_secrets != "" ? [1] : [])
      content {
        name = var.pod_partitions_in_database.image_pull_secrets
      }
    }
    restart_policy = "OnFailure" # Always, OnFailure, Never
    container {
      name              = var.pod_partitions_in_database.name
      image             = var.pod_partitions_in_database.tag != "" ? "${var.pod_partitions_in_database.image}:${var.pod_partitions_in_database.tag}" : var.pod_partitions_in_database.image
      image_pull_policy = var.pod_partitions_in_database.image_pull_policy
      command           = ["/script.sh"]
      env {
        name  = "MongoDB_Host"
        value = local.mongodb_host
      }
      env {
        name  = "MongoDB_Port"
        value = local.mongodb_port
      }
      dynamic env {
        for_each = local.pod_partitions_in_database_credentials
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
      volume_mount {
        name       = "script"
        mount_path = "/script.sh"
      }
      dynamic volume_mount {
        for_each = (local.mongodb_certificates_secret != "" ? [1] : [])
        content {
          name       = "mongodb-secret-volume"
          mount_path = "/mongodb"
          read_only  = true
        }
      }
    }
    volume {
      name = "script"
      host_path {
        path = "${path.cwd}/generated/script.sh"
      }
    }
    dynamic volume {
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

locals {
  script = <<EOF
#!/bin/bash
mongosh --tlsCAFile /mongodb/${local.mongodb_certificates_ca_filename} --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB_User --password $MongoDB_Password mongodb://${local.mongodb_host}:${local.mongodb_port}/database --eval 'db.PartitionData.insertMany(${jsonencode(local.partitions_data)})'
EOF
}

resource "local_file" "script" {
  filename = "${path.cwd}/generated/script.sh"
  content  = local.script
}

