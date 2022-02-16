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

# Node selector
node_selector = { lifecycle = "OnDemand" }

# Monitoring infos
monitoring = {
  seq        = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/seq"
    tag          = "2021.4"
    service_type = "LoadBalancer"
    use          = true
  }
  grafana    = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/grafana"
    tag          = "latest"
    service_type = "LoadBalancer"
    use          = true
  }
  prometheus = {
    image         = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/prometheus"
    tag           = "latest"
    service_type  = "ClusterIP"
    use           = true
    node_exporter = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/node-exporter"
      tag   = "latest"
    }
  }
}
