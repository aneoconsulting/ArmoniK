resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
  metadata {
    name      = local.hpa_name
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "autoscaling"
      service = "hpa"
    }
  }
  spec {
    min_replicas = local.hpa_min_replicas
    max_replicas = local.hpa_max_replicas
    scale_target_ref {
      kind = local.hpa_scale_target_ref_kind
      name = local.hpa_scale_target_ref_name
    }
    metric {
      type = "Object"
      object {
        described_object {
          api_version = ""
          kind        = "Service"
          name        = kubernetes_service.metrics_exporter.metadata.0.name
        }
        metric {
          name = local.hpa_metric_name
        }
        dynamic target {
          for_each = (local.hpa_metric_target_type != "" ? [1] : [])
          content {
            type                = local.hpa_metric_target_type
            value               = local.hpa_metric_target_value
            average_utilization = local.hpa_metric_target_average_utilization
            average_value       = local.hpa_metric_target_average_value
          }
        }
      }
    }
  }
}