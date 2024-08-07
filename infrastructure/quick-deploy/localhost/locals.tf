locals {
  config_list_control_plane    = concat(module.activemq, module.redis, [module.mongodb])
  config_list_polling_agent    = concat(module.activemq, module.redis, [module.mongodb])
  config_list_worker           = []
  config_list_metrics_exporter = concat(module.activemq, module.redis, [module.mongodb])
  config_database              = module.mongodb

  grafana_output = {
    host = module.grafana[0].host
    port = module.grafana[0].port
    url  = module.grafana[0].url
  }
  fluent_bit_output = {
    configmaps = {
      config  = module.fluent_bit.configmaps.config
      envvars = module.fluent_bit.configmaps.envvars
    }
    container_name = module.fluent_bit.container_name
    image          = module.fluent_bit.image
    is_daemonset   = module.fluent_bit.is_daemonset
    tag            = module.fluent_bit.tag
  }
  prometheus_output = {
    host = module.prometheus.host
    port = module.prometheus.port
    url  = module.prometheus.url
  }
  metrics_exporter_output = {
    host      = module.metrics_exporter.host
    name      = module.metrics_exporter.name
    namespace = module.metrics_exporter.namespace
    port      = module.metrics_exporter.port
    url       = module.metrics_exporter.url
  }
  seq_output = {
    host    = module.seq[0].host
    port    = module.seq[0].port
    url     = module.seq[0].url
    web_url = module.seq[0].web_url
  }
}
