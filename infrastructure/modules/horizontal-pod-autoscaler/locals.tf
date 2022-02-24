locals {
  # Metrics exporter
  metrics_exporter_name  = lookup(var.metrics_exporter, "name", "armonik-metrics-exporter")
  metrics_exporter_image = lookup(var.metrics_exporter, "image", "")
  metrics_exporter_tag   = lookup(var.metrics_exporter, "tag", "")

  # API service
  api_service_name                     = lookup(var.api_service, "name", "armonik-api-service")
  api_service_group                    = lookup(var.api_service, "group", "custom.metrics.k8s.io")
  api_service_group_priority_minimum   = tonumber(lookup(var.api_service, "group_priority_minimum", 1000))
  api_service_version                  = lookup(var.api_service, "version", "v1beta1")
  api_service_version_priority         = tonumber(lookup(var.api_service, "version_priority", 5))
  api_service_insecure_skip_tls_verify = tobool(lookup(var.api_service, "insecure_skip_tls_verify", true))

  # HPA
  hpa_name                              = lookup(var.hpa, "name", "hpa")
  hpa_min_replicas                      = tonumber(lookup(lookup(var.hpa, "replicas", {}), "min", 1))
  hpa_max_replicas                      = tonumber(lookup(lookup(var.hpa, "replicas", {}), "max", 2))
  hpa_scale_target_ref_kind             = lookup(lookup(var.hpa, "scale_target_ref", {}), "kind", "")
  hpa_scale_target_ref_name             = lookup(lookup(var.hpa, "scale_target_ref", {}), "name", "")
  hpa_metric_name                       = lookup(lookup(var.hpa, "metric", {}), "name", "")
  hpa_metric_target_type                = lookup(lookup(lookup(var.hpa, "metric", {}), "target", {}), "type", "")
  hpa_metric_target_average_value       = lookup(lookup(lookup(var.hpa, "metric", {}), "target", {}), "average_value", "")
  hpa_metric_target_average_utilization = lookup(lookup(lookup(var.hpa, "metric", {}), "target", {}), "average_utilization", "")
  hpa_metric_target_value               = lookup(lookup(lookup(var.hpa, "metric", {}), "target", {}), "value", "")
}