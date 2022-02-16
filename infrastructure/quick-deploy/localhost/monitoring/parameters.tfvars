# Kubernetes namespace
namespace = "armonik"

# Node selector
node_selector = {}

# Monitoring infos
monitoring = {
  seq        = {
    image        = "datalust/seq"
    tag          = "2021.4"
    service_type = "LoadBalancer"
    use          = true
  }
  grafana    = {
    image        = "grafana/grafana"
    tag          = "latest"
    service_type = "LoadBalancer"
    use          = true
  }
  prometheus = {
    image         = "prom/prometheus"
    tag           = "latest"
    service_type  = "ClusterIP"
    use           = true
    node_exporter = {
      image = "prom/node-exporter"
      tag   = "latest"
    }
  }
}
