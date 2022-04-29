/*resource "kubernetes_horizontal_pod_autoscaler" "compute_plane_hpa" {
  count = length(var.compute_plane)
  metadata {
    name      = "${var.compute_plane[count.index].name}-hpa"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "autoscaling"
      service = "${var.compute_plane[count.index].name}-hpa"
    }
  }
  spec {
    min_replicas = var.compute_plane[count.index].hpa.min_replicas
    max_replicas = var.compute_plane[count.index].hpa.max_replicas
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = var.compute_plane[count.index].name
    }
    #target_cpu_utilization_percentage = 50
    dynamic metric {
      for_each = var.compute_plane[count.index].hpa.object_metrics
      content {
        type = "Object"
        object {
          described_object {
            api_version = metric.value.described_object.api_version
            kind        = metric.value.described_object.kind
            name        = local.metrics_exporter_name
          }
          metric {
            name = metric.value.metric_name
          }
          target {
            type                = metric.value.target.type
            average_value       = metric.value.target.average_value
            value               = metric.value.target.value
            average_utilization = metric.value.target.average_utilization
          }
        }
      }
    }
  }
}
*/