# SUFFIX
suffix = "main"

# Namespace
namespace = "armonik"

# Seq
seq = {
  node_selector = { service = "monitoring" }
}

# Node exporter
#node_exporter = {
#  node_selector = {}
#}

# Metrics exporter
metrics_exporter = {
  node_selector = { service = "metrics" }
  extra_conf = {
    MongoDB__AllowInsecureTls              = true
    Serilog__MinimumLevel                  = "Information"
    MongoDB__TableStorage__PollingDelayMin = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax = "00:00:10"
    MongoDB__DataRetention                 = "1.00:00:00" # 1 day retention
  }
}

# Partition metrics exporter
#parition_metrics_exporter = {
#  node_selector = { service = "metrics" }
#  extra_conf    = {
#    MongoDB__AllowInsecureTls           = true
#    Serilog__MinimumLevel               = "Information"
#    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
#    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
#    MongoDB__DataRetention                 = "1.00:00:00" # 1 day retention
#  }
#}

# Prometheus
prometheus = {
  node_selector = { service = "metrics" }
}

# Grafana
grafana = {
  node_selector = { service = "monitoring" }
}

# Fluent-bit
fluent_bit = {
  is_daemonset  = true
  node_selector = {}
}