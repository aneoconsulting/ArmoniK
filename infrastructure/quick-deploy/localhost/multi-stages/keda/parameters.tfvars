# Kubernetes namespace
namespace = "default"

# Keda infos
keda = {
  docker_image = {
    keda = {
      image = "ghcr.io/kedacore/keda"
      tag   = "2.9.3"
    }
    metricsApiServer = {
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.9.3"
    }
  }
  image_pull_secrets              = ""
  node_selector                   = {}
  metrics_server_dns_policy       = "ClusterFirst"
  metrics_server_use_host_network = false
  helm_chart_repository           = "https://kedacore.github.io/charts"
  helm_chart_version              = "2.9.4"
}
