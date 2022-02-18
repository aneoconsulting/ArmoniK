output "monitoring" {
  description = "Monitoring endpoint URLs"
  value       = {
    seq        = (var.monitoring.seq.use ? {
      host    = module.seq.0.host
      port    = module.seq.0.port
      url     = module.seq.0.url
      web_url = module.seq.0.web_url
    } : {})
    grafana    = (var.monitoring.grafana.use ? {
      host = module.grafana.0.host
      port = module.grafana.0.port
      url  = module.grafana.0.url
    } : {})
    prometheus = (var.monitoring.prometheus.use ? {
      host = module.prometheus.0.host
      port = module.prometheus.0.port
      url  = module.prometheus.0.url
    } : {})
  }
}