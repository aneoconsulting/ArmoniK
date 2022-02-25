# Kubernetes namespace
namespace = "armonik"

# Monitoring infos
monitoring = {
  seq        = {
    image         = "datalust/seq"
    tag           = "2021.4"
    service_type  = "LoadBalancer"
    enabled       = true
    node_selector = {}
  }
  grafana    = {
    image         = "grafana/grafana"
    tag           = "latest"
    service_type  = "LoadBalancer"
    enabled       = true
    node_selector = {}
  }
  prometheus = {
    image         = "prom/prometheus"
    tag           = "latest"
    service_type  = "ClusterIP"
    enabled       = true
    node_selector = {}
    node_exporter = {
      image = "prom/node-exporter"
      tag   = "latest"
    }
  }
  fluent_bit = {
    image          = "fluent/fluent-bit"
    tag            = "1.7.2"
    is_daemonset   = false
    http_port      = 2020 # 0 or 2020
    read_from_head = true
    node_selector  = {}
  }
}
