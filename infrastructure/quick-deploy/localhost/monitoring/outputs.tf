output "monitoring" {
  description = "Monitoring endpoint URLs"
  value       = {
    seq        = {
      host    = module.seq.0.host
      port    = module.seq.0.port
      url     = module.seq.0.url
      web_url = module.seq.0.web_url
    }
    grafana    = {
      host = module.grafana.0.host
      port = module.grafana.0.port
      url  = module.grafana.0.url
    }
    prometheus = {
      host = module.prometheus.0.host
      port = module.prometheus.0.port
      url  = module.prometheus.0.url
    }
  }
}