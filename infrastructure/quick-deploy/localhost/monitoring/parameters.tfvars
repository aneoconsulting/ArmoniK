# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Monitoring infos
monitoring = {
  seq              = {
    enabled            = true
    image              = "datalust/seq"
    tag                = "2022.1"
    port               = 8080
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  grafana          = {
    enabled            = true
    image              = "grafana/grafana"
    tag                = "8.5.5"
    port               = 3000
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  node_exporter    = {
    enabled            = true
    image              = "prom/node-exporter"
    tag                = "v1.3.1"
    image_pull_secrets = ""
    node_selector      = {}
  }
  prometheus       = {
    image              = "prom/prometheus"
    tag                = "v2.36.1"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  metrics_exporter = {
    image              = "dockerhubaneo/armonik_control_metrics"
    tag                = "0.5.13"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  fluent_bit       = {
    image              = "fluent/fluent-bit"
    tag                = "1.9.5"
    image_pull_secrets = ""
    is_daemonset       = false
    http_port          = 2020 # 0 or 2020
    read_from_head     = true
    node_selector      = {}
  }
}
