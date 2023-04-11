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
  seq = {
    enabled            = true
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/seq"
    tag                = "2023.1"
    port               = 8080
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
    system_ram_target  = 0.2
  }
  grafana = {
    enabled            = true
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/grafana"
    tag                = "9.3.6"
    port               = 3000
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
  }
  node_exporter = {
    enabled            = true
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/node-exporter"
    tag                = "v1.5.0"
    image_pull_secrets = ""
    node_selector      = { "grid/type" = "Operator" }
  }
  prometheus = {
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/prometheus"
    tag                = "v2.42.0"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
  }
  metrics_exporter = {
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/metrics-exporter"
    tag                = "0.12.4"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
    }
  }
  partition_metrics_exporter = {
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/partition-metrics-exporter"
    tag                = "0.12.4"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { "grid/type" = "Operator" }
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
    }
  }
  cloudwatch = {
    enabled           = true
    kms_key_id        = ""
    retention_in_days = 30
  }
  fluent_bit = {
    image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/fluent-bit"
    tag                = "2.0.9"
    image_pull_secrets = ""
    is_daemonset       = true
    http_port          = 2020 # 0 or 2020
    read_from_head     = true
    node_selector      = { "grid/type" = "Operator" }
  }
}

authentication = false
