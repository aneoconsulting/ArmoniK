locals {
  # Keda
  keda_namespace                       = try(var.namespace, "default")
  keda_keda_image                      = try(var.keda.docker_image.keda.image, "ghcr.io/kedacore/keda")
  keda_keda_tag                        = try(var.keda.docker_image.keda.tag, "2.6.1")
  keda_metricsApiServer_image          = try(var.keda.docker_image.metricsApiServer.image, "ghcr.io/kedacore/keda-metrics-apiserver")
  keda_metricsApiServer_tag            = try(var.keda.docker_image.metricsApiServer.tag, "2.6.1")
  keda_image_pull_secrets              = try(var.keda.image_pull_secrets, "")
  keda_node_selector                   = try(var.keda.node_selector, {})
  keda_metrics_server_dns_policy       = try(var.keda.metrics_server_dns_policy, "ClusterFirst")
  keda_metrics_server_use_host_network = try(var.keda.metrics_server_use_host_network, false)
  keda_chart_repository                = try(coalesce(var.keda.helm_chart_repository), "https://kedacore.github.io/charts")
  keda_chart_version                   = try(coalesce(var.keda.helm_chart_version), "2.9.4")
}
