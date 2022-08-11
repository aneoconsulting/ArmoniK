# Kubernetes namespace
namespace = "default"

# Keda infos
keda = {
  docker_image       = {
    keda             = {
      image = "ghcr.io/kedacore/keda"
      tag   = "2.8.0"
    }
    metricsApiServer = {
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.8.0"
    }
  }
  image_pull_secrets = ""
  node_selector      = {}
}
