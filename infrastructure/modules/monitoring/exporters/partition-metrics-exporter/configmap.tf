# configmap with all the variables
resource "kubernetes_config_map" "partition_metrics_exporter_config" {
  metadata {
    name      = "partition-metrics-exporter-configmap"
    namespace = var.namespace
  }
  data = merge(var.extra_conf, {
    MongoDB__CAFile           = (local.mongodb_certificates_secret != "" ? "/mongodb/chain.pem" : "")
    MongoDB__ReplicaSetName   = "rs0"
    MongoDB__DatabaseName     = "database"
    MongoDB__DataRetention    = "10.00:00:00"
    MongoDB__DirectConnection = "true"
    MongoDB__Tls              = "true"
    MetricsExporter__Host     = "http://${local.metrics_exporter_host}"
    MetricsExporter__Port     = local.metrics_exporter_port
    MetricsExporter__Path     = "/metrics"
  })
}
