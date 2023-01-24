# configmap with all the variables
resource "kubernetes_config_map" "partition_metrics_exporter_config" {
  metadata {
    name      = "partition-metrics-exporter-configmap"
    namespace = var.namespace
  }
  data = {
    Serilog__MinimumLevel               = var.logging_level
    MongoDB__CAFile                     = (local.mongodb_certificates_secret != "" ? "/mongodb/${local.mongodb_certificates_ca_filename}" : "")
    MongoDB__ReplicaSetName             = "rs0"
    MongoDB__DatabaseName               = "database"
    MongoDB__DataRetention              = "10.00:00:00"
    MongoDB__AllowInsecureTls           = local.mongodb_allow_insecure_tls
    MongoDB__DirectConnection           = "true"
    MongoDB__Tls                        = "true"
    MongoDB__TableStorage__PollingDelay = "00:00:01"
    MetricsExporter__Host               = "http://${local.metrics_exporter_host}"
    MetricsExporter__Port               = local.metrics_exporter_port
    MetricsExporter__Path               = "/metrics"
  }
}
