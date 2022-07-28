# Kubernetes namespace
namespace = "kube-system"

# metrics server info
docker_image = {
  image = "k8s.gcr.io/metrics-server/metrics-server"
  tag   = "v0.6.1"
}

# Image pull secret
image_pull_secrets = ""

# node selector
node_selector = {}

# Default args
default_args = [
  "--cert-dir=/tmp",
  "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
  "--kubelet-use-node-status-port",
  "--metric-resolution=15s"
]

# Host network
host_network = false
