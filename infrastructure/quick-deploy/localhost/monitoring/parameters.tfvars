# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Monitoring infos
monitoring = {
  seq = {
    enabled            = true
    image              = "datalust/seq"
    tag                = "2022.1"
    port               = 8080
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
    system_ram_target  = 0.2
  }
  grafana = {
    enabled            = true
    image              = "grafana/grafana"
    tag                = "9.2.1"
    port               = 3000
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  node_exporter = {
    enabled            = true
    image              = "prom/node-exporter"
    tag                = "v1.3.1"
    image_pull_secrets = ""
    node_selector      = {}
  }
  prometheus = {
    image              = "prom/prometheus"
    tag                = "v2.36.1"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  metrics_exporter = {
    image              = "dockerhubaneo/armonik_control_metrics"
    tag                = "0.8.1"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  partition_metrics_exporter = {
    image              = "dockerhubaneo/armonik_control_partition_metrics"
    tag                = "0.8.1"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  fluent_bit = {
    image              = "fluent/fluent-bit"
    tag                = "1.9.9"
    image_pull_secrets = ""
    is_daemonset       = true
    http_port          = 2020 # 0 or 2020
    read_from_head     = true
    node_selector      = {}
  }
}

authentication = false
