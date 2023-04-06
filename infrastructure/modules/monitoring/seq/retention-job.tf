resource "kubernetes_cron_job_v1" "retention_job_in_seq" {
  metadata {
    name      = "seq-retention-job"
    namespace = var.namespace
    labels = {
      app     = "seq"
      service = "seq-retention-job"
      type    = "monitoring"
    }
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    starting_deadline_seconds     = 20
    successful_jobs_history_limit = 0
    suspend                       = false
    schedule                      = "0 0 * * *"
    job_template {
      metadata {
        name = "seq-retention-job"
        labels = {
          app     = "seq"
          service = "seq-retention-job"
          type    = "monitoring"
        }
      }
      spec {
        template {
          metadata {
            name = "seq-retention-job"
            labels = {
              app     = "seq"
              service = "seq-retention-job"
              type    = "monitoring"
            }
          }
          spec {
            node_selector = var.node_selector
            dynamic "toleration" {
              for_each = (var.node_selector != {} ? [
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
              for_each = (var.docker_image_cron.image_pull_secrets != "" ? [1] : [])
              content {
                name = var.docker_image_cron.image_pull_secrets
              }
            }
            restart_policy = "OnFailure" # Always, OnFailure, Never
            container {
              name              = "seq-retention-job"
              image             = var.docker_image_cron.tag != "" ? "${var.docker_image_cron.image}:${var.docker_image_cron.tag}" : var.docker_image_cron.image
              image_pull_policy = var.docker_image_cron.image_pull_secrets
              command           = ["/bin/bash", "-c", local.script_cron]
              env {
                name  = "SEQ_URL"
                value = local.seq_web_url
              }
              env {
                name  = "SEQ_USER"
                value = var.authentication ? "admin" : ""
              }
              env {
                name  = "SEQ_PASSWORD"
                value = var.authentication ? "adminadmin" : ""
              }
            }
          }
        }
        backoff_limit = 5
      }
    }
  }
}

locals {
  script_cron = <<EOF
#!/bin/bash
token=$(/bin/seqcli/seqcli apikey create -t "test ApiKey" --permissions=Project --connect-username=$SEQ_USER --connect-password=$SEQ_PASSWORD -s $SEQ_URL)
/bin/seqcli/seqcli retention create --after ${var.retention_in_days} --delete-all-events --apikey=$token -s $SEQ_URL
EOF
}
