# Agent deployment
resource "kubernetes_deployment" "compute_plane" {
  for_each = toset(local.partition_names)
  metadata {
    name      = "compute-plane-${each.key}"
    namespace = var.namespace
    labels = {
      app       = "armonik"
      service   = "compute-plane"
      partition = each.key
    }
  }
  spec {
    replicas = var.compute_plane[each.key].replicas
    selector {
      match_labels = {
        app       = "armonik"
        service   = "compute-plane"
        partition = each.key
      }
    }
    template {
      metadata {
        name      = "${each.key}-compute-plane"
        namespace = var.namespace
        labels = {
          app       = "armonik"
          service   = "compute-plane"
          partition = each.key
        }
        annotations = local.compute_plane_annotations[each.key]
      }
      spec {
        node_selector = local.compute_plane_node_selector[each.key]
        dynamic "toleration" {
          for_each = (local.compute_plane_node_selector[each.key] != {} ? [
            for index in range(0, length(local.compute_plane_node_selector_keys[each.key])) : {
              key   = local.compute_plane_node_selector_keys[each.key][index]
              value = local.compute_plane_node_selector_values[each.key][index]
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        termination_grace_period_seconds = var.compute_plane[each.key].termination_grace_period_seconds
        share_process_namespace          = false
        security_context {}
        dynamic "image_pull_secrets" {
          for_each = (var.compute_plane[each.key].image_pull_secrets != "" ? [1] : [])
          content {
            name = var.compute_plane[each.key].image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # Polling agent container
        container {
          name              = "polling-agent"
          image             = var.compute_plane[each.key].polling_agent.tag != "" ? "${var.compute_plane[each.key].polling_agent.image}:${var.compute_plane[each.key].polling_agent.tag}" : var.compute_plane[each.key].polling_agent.image
          image_pull_policy = var.compute_plane[each.key].polling_agent.image_pull_policy
          security_context {
            capabilities {
              drop = ["SYS_PTRACE"]
            }
          }
          resources {
            limits   = var.compute_plane[each.key].polling_agent.limits
            requests = var.compute_plane[each.key].polling_agent.requests
          }
          port {
            name           = "poll-agent-port"
            container_port = 1080
          }
          liveness_probe {
            http_get {
              path = "/liveness"
              port = 1080
            }
            initial_delay_seconds = 15
            period_seconds        = 5
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 1
          }
          startup_probe {
            http_get {
              path = "/startup"
              port = 1080
            }
            initial_delay_seconds = 1
            period_seconds        = 3
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 20
            # the pod has (period_seconds x failure_threshold) seconds to finalize its startup
          }
          dynamic "env_from" {
            for_each = local.polling_agent_configmaps
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }
          env {
            name  = "Amqp__PartitionId"
            value = each.key
          }
          dynamic "env" {
            for_each = local.credentials
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
            name       = "cache-volume"
            mount_path = "/cache"
          }
          dynamic "volume_mount" {
            for_each = local.certificates
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              read_only  = true
            }
          }
        }
        # Containers of worker
        dynamic "container" {
          iterator = worker
          for_each = var.compute_plane[each.key].worker
          content {
            name              = "${worker.value.name}-${worker.key}"
            image             = worker.value.tag != "" ? "${worker.value.image}:${worker.value.tag}" : worker.value.image
            image_pull_policy = worker.value.image_pull_policy
            resources {
              limits   = worker.value.limits
              requests = worker.value.requests
            }
            lifecycle {
              pre_stop {
                exec {
                  command = ["/bin/sh", "-c", local.pre_stop_wait_script]
                }
              }
            }
            dynamic "env_from" {
              for_each = local.worker_configmaps
              content {
                config_map_ref {
                  name = env_from.value
                }
              }
            }
            volume_mount {
              name       = "cache-volume"
              mount_path = "/cache"
            }
            dynamic "volume_mount" {
              for_each = (local.check_file_storage_type == "FS" ? [1] : [])
              content {
                name       = "shared-volume"
                mount_path = "/data"
                read_only  = true
              }
            }
          }
        }
        volume {
          name = "cache-volume"
          empty_dir {}
        }
        dynamic "volume" {
          for_each = (local.lower_file_storage_type == "nfs" ? [1] : [])
          content {
            name = "shared-volume"
            nfs {
              path      = local.host_path
              server    = local.file_server_ip
              read_only = true
            }
          }
        }
        dynamic "volume" {
          for_each = (local.lower_file_storage_type == "hostpath" ? [1] : [])
          content {
            name = "shared-volume"
            host_path {
              path = local.host_path
              type = "Directory"
            }
          }
        }
        dynamic "volume" {
          for_each = local.certificates
          content {
            name = volume.value.name
            secret {
              secret_name = volume.value.secret_name
              optional    = false
            }
          }
        }
        # Fluent-bit container
        dynamic "container" {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name              = local.fluent_bit_container_name
            image             = "${local.fluent_bit_image}:${local.fluent_bit_tag}"
            image_pull_policy = "IfNotPresent"
            env_from {
              config_map_ref {
                name = local.fluent_bit_envvars_configmap
              }
            }
            lifecycle {
              pre_stop {
                exec {
                  command = ["/bin/sh", "-c", local.pre_stop_wait_script]
                }
              }
            }
            volume_mount {
              name       = "cache-volume"
              mount_path = "/cache"
              read_only  = true
            }
            # Please don't change below read-only permissions
            dynamic "volume_mount" {
              for_each = local.fluent_bit_volumes
              content {
                name       = volume_mount.key
                mount_path = volume_mount.value.mount_path
                read_only  = volume_mount.value.read_only
              }
            }
          }
        }
        dynamic "volume" {
          for_each = local.fluent_bit_volumes
          content {
            name = volume.key
            dynamic "host_path" {
              for_each = (volume.value.type == "host_path" ? [1] : [])
              content {
                path = volume.value.mount_path
              }
            }
            dynamic "config_map" {
              for_each = (volume.value.type == "config_map" ? [1] : [])
              content {
                name = local.fluent_bit_configmap
              }
            }
          }
        }
      }
    }
  }
}


locals {
  pre_stop_wait_script = <<EOF

while test -e /cache/armonik_agent.sock ; do
  sleep 1
done

EOF
}
