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
    enabled            = true
    image              = "prom/prometheus"
    tag                = "latest"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  prometheus_adapter = {
    enabled            = true
    image              = "k8s.gcr.io/prometheus-adapter/prometheus-adapter"
    tag                = "v0.9.1"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {
      "beta.kubernetes.io/arch"          = "amd64"
      "beta.kubernetes.io/instance-type" = "k3s"
      "beta.kubernetes.io/os"            = "linux"
    }
  }
  metrics_exporter   = {
    enabled            = true
    image              = "dockerhubaneo/armonik_control_metrics"
    tag                = "0.4.1-newtaskcreationapi.59.65dc09e"
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
