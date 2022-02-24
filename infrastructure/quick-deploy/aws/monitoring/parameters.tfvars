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
node_selector = { "grid/type" = "Operator" }

# Monitoring infos
monitoring = {
  seq        = {
    enabled      = true
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/seq"
    tag          = "2021.4"
    service_type = "LoadBalancer"
  }
  grafana    = {
    enabled      = true
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/grafana"
    tag          = "latest"
    service_type = "LoadBalancer"
  }
  prometheus = {
    enabled       = true
    image         = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/prometheus"
    tag           = "latest"
    service_type  = "ClusterIP"
    node_exporter = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/node-exporter"
      tag   = "latest"
    }
  }
  cloudwatch = {
    enabled           = true
    kms_key_id        = ""
    retention_in_days = 30
  }
  fluent_bit = {
    image          = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/fluent-bit"
    tag            = "1.7.2"
    is_daemonset   = true
    http_port      = 2020 # 0 or 2020
    read_from_head = true
  }
}
