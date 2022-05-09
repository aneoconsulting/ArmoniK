# Kubernetes namespace
namespace = "default"

# Keda infos
keda = {
  docker_image       = {
    keda             = {
      image = "ghcr.io/kedacore/keda"
      tag   = "2.6.1"
    }
    metricsApiServer = {
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.6.1"
    }
  }
  image_pull_secrets = ""
  node_selector      = {}
}
