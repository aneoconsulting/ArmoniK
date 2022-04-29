locals {
  # Keda
  keda_namespace              = try(var.namespace, "default")
  keda_keda_image             = try(var.keda.docker_image.keda.image, "ghcr.io/kedacore/keda")
  keda_keda_tag               = try(var.keda.docker_image.keda.tag, "2.6.1")
  keda_metricsApiServer_image = try(var.keda.docker_image.metricsApiServer.image, "ghcr.io/kedacore/keda-metrics-apiserver")
  keda_metricsApiServer_tag   = try(var.keda.docker_image.metricsApiServer.tag, "2.6.1")
  keda_node_selector          = try(var.keda.node_selector, "default")
}