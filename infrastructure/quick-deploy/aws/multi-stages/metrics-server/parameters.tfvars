# Profile
profile = "default"

# Region
region = "eu-west-3"

# Kubernetes namespace
namespace = "kube-system"

# Suffix
suffix = "main"

# metrics server info
docker_image = {
  image = "metrics-server"
  tag   = "v0.6.2"
}

# Image pull secret
image_pull_secrets = ""

# node selector
node_selector = { service = "monitoring" }

# args
args = [
  "--cert-dir=/tmp",
  "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
  "--kubelet-use-node-status-port",
  "--metric-resolution=15s"
]

# Host network
host_network = false

# Repository of helm chart
helm_chart_repository = "https://kubernetes-sigs.github.io/metrics-server/"

# Version of helm chart
helm_chart_version = "3.8.3"