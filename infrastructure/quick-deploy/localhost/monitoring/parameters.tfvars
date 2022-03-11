# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Monitoring infos
monitoring = {
  seq                = {
    enabled            = true
    image              = "datalust/seq"
    tag                = "2021.4"
    image_pull_secrets = ""
    service_type       = "LoadBalancer"
    node_selector      = {}
  }
  grafana            = {
    enabled            = true
    image              = "grafana/grafana"
    tag                = "latest"
    image_pull_secrets = ""
    service_type       = "LoadBalancer"
    node_selector      = {}
  }
  node_exporter      = {
    enabled            = true
    image              = "prom/node-exporter"
    tag                = "latest"
    image_pull_secrets = ""
    node_selector      = {}
  }
  prometheus         = {
    image              = "prom/prometheus"
    tag                = "latest"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  prometheus_adapter = {
    image              = "k8s.gcr.io/prometheus-adapter/prometheus-adapter"
    tag                = "v0.9.1"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  metrics_exporter   = {
    image              = "dockerhubaneo/armonik_control_metrics"
    tag                = "0.5.1-opti.4.9725eeb"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  fluent_bit         = {
    image              = "fluent/fluent-bit"
    tag                = "1.7.2"
    image_pull_secrets = ""
    is_daemonset       = false
    http_port          = 2020 # 0 or 2020
    read_from_head     = true
    node_selector      = {}
  }
}
