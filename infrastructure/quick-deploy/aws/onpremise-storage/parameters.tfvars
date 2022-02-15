# Profile
profile = "default"

# Region
region = "eu-west-3"

# Kubeconfig path
k8s_config_path = "~/.kube/config"

# Kubeconfig context
k8s_config_context = "default"

# Kubernetes namespace
namespace = "armonik"

# Parameters for MongoDB
mongodb = {
  image         = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/mongodb"
  tag           = "4.4.11"
  node_selector = { lifecycle = "OnDemand" }
}