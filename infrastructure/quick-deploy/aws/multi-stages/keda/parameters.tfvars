# Profile
profile = "default"

# Region
region = "eu-west-3"

# Suffix
suffix = "main"

# Kubernetes namespace
namespace = "default"

# Keda infos
keda = {
  docker_image = {
    keda = {
      image = "keda"
      tag   = "2.13.1"
    }
    metrics_api_server = {
      image = "keda-metrics-apiserver"
      tag   = "2.13.1"
    }
  }
  image_pull_secrets              = ""
  node_selector                   = { service = "monitoring" }
  metrics_server_dns_policy       = "ClusterFirst"
  metrics_server_use_host_network = false
  helm_chart_repository           = "https://kedacore.github.io/charts"
  helm_chart_version              = "2.13.2"
}