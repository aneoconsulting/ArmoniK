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

# Logging level
logging_level = "Information"

tags = {
  "name"             = ""
  "env"              = ""
  "entity"           = ""
  "bu"               = ""
  "owner"            = ""
  "application code" = ""
  "project code"     = ""
  "cost center"      = ""
  "Support Contact"  = ""
  "origin"           = "terraform"
  "unit of measure"  = ""
  "epic"             = ""
  "functional block" = ""
  "hostname"         = ""
  "interruptible"    = ""
  "tostop"           = ""
  "tostart"          = ""
  "branch"           = ""
  "gridserver"       = ""
  "it division"      = ""
  "Confidentiality"  = ""
  "csp"              = "aws"
  "grafanaserver"    = ""
  "Terraform"        = "true"
  "DST_Update"       = ""
}

# Monitoring infos
monitoring = {
  seq              = {
    enabled            = true
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/seq"
    tag                = "2021.4"
    port               = 8080
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
  }
  grafana          = {
    enabled            = true
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/grafana"
    tag                = "latest"
    port               = 3000
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
  }
  node_exporter    = {
    enabled            = true
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/node-exporter"
    tag                = "latest"
    image_pull_secrets = ""
    node_selector      = { "grid/type" = "Operator" }
  }
  prometheus       = {
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/prometheus"
    tag                = "latest"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
  }
  metrics_exporter = {
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/metrics-exporter"
    tag                = "0.5.8"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
  }
  cloudwatch       = {
    enabled           = true
    kms_key_id        = ""
    retention_in_days = 30
  }
  fluent_bit       = {
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/fluent-bit"
    tag                = "1.7.2"
    image_pull_secrets = ""
    is_daemonset       = true
    http_port          = 2020 # 0 or 2020
    read_from_head     = true
    node_selector      = { "grid/type" = "Operator" }
  }
}
