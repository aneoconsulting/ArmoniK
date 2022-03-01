output "monitoring" {
  description = "Monitoring endpoint URLs"
  value       = {
    seq        = (local.seq_enabled ? {
      host    = module.seq.0.host
      port    = module.seq.0.port
      url     = module.seq.0.url
      web_url = module.seq.0.web_url
      enabled = true
    } : {})
    grafana    = (local.grafana_enabled ? {
      host    = module.grafana.0.host
      port    = module.grafana.0.port
      url     = module.grafana.0.url
      enabled = true
    } : {})
    prometheus = {
      host = module.prometheus.host
      port = module.prometheus.port
      url  = module.prometheus.url
    }
    cloudwatch = (local.cloudwatch_enabled ? {
      name    = module.cloudwatch.0.name
      region  = var.region
      enabled = true
    } : {})
    fluent_bit = {
      container_name = module.fluent_bit.container_name
      image          = module.fluent_bit.image
      tag            = module.fluent_bit.tag
      is_daemonset   = module.fluent_bit.is_daemonset
      configmaps     = {
        envvars = module.fluent_bit.configmaps.envvars
        config  = module.fluent_bit.configmaps.config
      }
    }
  }
}