# Profile
profile = "default"

# Region
region = "eu-west-3"

# Kubernetes namespace
namespace = "default"

# Keda infos
keda = {
  docker_image       = {
    keda             = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/keda"
      tag   = "2.6.1"
    }
    metricsApiServer = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/keda-metrics-apiserver"
      tag   = "2.6.1"
    }
  }
  image_pull_secrets = ""
  node_selector      = { "grid/type" = "Operator" }
}
