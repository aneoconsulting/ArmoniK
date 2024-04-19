# Kubernetes namespace
namespace = "armonik"

# Monitoring infos
monitoring = {
  seq        = {}
  fluent_bit = {}
  partition_metrics_exporter = {
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
      MongoDB__DataRetention                 = "1.00:00:00" # 1 day retention
    }
  }
  metrics_exporter = {
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
      MongoDB__DataRetention                 = "1.00:00:00" # 1 day retention
    }
  }
  node_exporter = {}
  prometheus    = {}
  grafana       = {}
}
/*
monitoring = {
  seq = {
    enabled                = true
    image                  = "datalust/seq"
    tag                    = "2023.3"
    port                   = 8080
    image_pull_secrets     = ""
    service_type           = "ClusterIP"
    node_selector          = {}
    system_ram_target      = 0.2
    cli_image              = "datalust/seqcli"
    cli_tag                = "2023.2"
    cli_image_pull_secrets = ""
    retention_in_days      = "2d"
  }
  grafana = {
    enabled            = true
    image              = "grafana/grafana"
    tag                = "10.0.2"
    port               = 3000
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  node_exporter = {
    enabled            = true
    image              = "prom/node-exporter"
    tag                = "v1.6.0"
    image_pull_secrets = ""
    node_selector      = {}
  }
  prometheus = {
    image              = "prom/prometheus"
    tag                = "v2.45.0"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
  }
  metrics_exporter = {
    image              = "dockerhubaneo/armonik_control_metrics"
    tag                = "0.23.3"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
      MongoDB__DataRetention = "1.00:00:00"
    }
  }
  partition_metrics_exporter = {
    image              = "dockerhubaneo/armonik_control_partition_metrics"
    tag                = "0.23.3"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = {}
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
      MongoDB__DataRetention = "1.00:00:00"
    }
  }
  fluent_bit = {
    image              = "fluent/fluent-bit"
    tag                = "2.1.7"
    image_pull_secrets = ""
    is_daemonset       = true
    http_port          = 2020 # 0 or 2020
    read_from_head     = true
    node_selector      = {}
    parser             = "docker"
  }
}
*/
authentication = false
