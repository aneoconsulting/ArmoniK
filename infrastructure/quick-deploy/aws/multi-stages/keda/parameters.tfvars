# Profile
profile = "default"

# Region
region = "eu-west-3"

# Kubernetes namespace
namespace = "default"

# Keda infos
keda = {
  docker_image = {
    keda = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/keda"
      tag   = "2.9.3"
    }
    metricsApiServer = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/keda-metrics-apiserver"
      tag   = "2.9.3"
    }
  }
  image_pull_secrets              = ""
  node_selector                   = { service = "monitoring" }
  metrics_server_dns_policy       = "ClusterFirst"
  metrics_server_use_host_network = false
  helm_chart_repository           = "https://kedacore.github.io/charts"
  helm_chart_version              = "2.9.4"
}