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
  image_pull_secrets = ""
  node_selector      = {}
}
