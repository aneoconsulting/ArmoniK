locals {
  # Seq
  seq_use          = tobool(lookup(lookup(var.monitoring, "seq", {}), "use", false))
  seq_image        = lookup(lookup(var.monitoring, "seq", {}), "image", "datalust/seq")
  seq_tag          = lookup(lookup(var.monitoring, "seq", {}), "tag", "2021.4")
  seq_service_type = lookup(lookup(var.monitoring, "seq", {}), "service_type", "LoadBalancer")

  # Grafana
  grafana_use          = tobool(lookup(lookup(var.monitoring, "grafana", {}), "use", false))
  grafana_image        = lookup(lookup(var.monitoring, "grafana", {}), "image", "grafana/grafana")
  grafana_tag          = lookup(lookup(var.monitoring, "grafana", {}), "tag", "latest")
  grafana_service_type = lookup(lookup(var.monitoring, "grafana", {}), "service_type", "LoadBalancer")

  # Prometheus
  prometheus_use                 = tobool(lookup(lookup(var.monitoring, "prometheus", {}), "use", false))
  prometheus_image               = lookup(lookup(var.monitoring, "prometheus", {}), "image", "prom/prometheus")
  prometheus_tag                 = lookup(lookup(var.monitoring, "prometheus", {}), "tag", "latest")
  prometheus_service_type        = lookup(lookup(var.monitoring, "prometheus", {}), "service_type", "ClusterIP")
  prometheus_node_exporter_image = lookup(lookup(lookup(var.monitoring, "prometheus", {}), "node_exporter", {}), "image", "prom/node-exporter")
  prometheus_node_exporter_tag   = lookup(lookup(lookup(var.monitoring, "prometheus", {}), "node_exporter", {}), "tag", "latest")

  # Fluent-bit
  fluent_bit_image          = lookup(lookup(var.monitoring, "fluent_bit", {}), "image", "fluent/fluent-bit")
  fluent_bit_tag            = lookup(lookup(var.monitoring, "fluent_bit", {}), "tag", "1.3.11")
  fluent_bit_is_daemonset   = tobool(lookup(lookup(var.monitoring, "fluent_bit", {}), "is_daemonset", false))
  fluent_bit_http_port      = tonumber(lookup(lookup(var.monitoring, "fluent_bit", {}), "http_port", 0))
  fluent_bit_read_from_head = tobool(lookup(lookup(var.monitoring, "fluent_bit", {}), "read_from_head", true))
}