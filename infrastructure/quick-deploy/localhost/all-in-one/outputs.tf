output "armonik" {
  description = "ArmoniK endpoint URL"
  value = {
    control_plane_url = module.armonik.endpoint_urls.control_plane_url
    grafana_url       = module.armonik.endpoint_urls.grafana_url
    seq_web_url       = module.armonik.endpoint_urls.seq_web_url
    admin_app_url     = module.armonik.endpoint_urls.admin_app_url
    admin_api_url     = module.armonik.endpoint_urls.admin_api_url
    admin_0_9_url     = module.armonik.endpoint_urls.admin_0_9_url
    admin_0_8_url     = module.armonik.endpoint_urls.admin_0_8_url
  }
}

output "rabbitmq" {
  description = "RabbitMQ endpoint URL"
  value = {
    epmd  = "http://${data.external.get_rabbitmq_ip.result.ip}:${data.external.get_rabbitmq_epmd_port.result.port}"
    amqp  = "http://${data.external.get_rabbitmq_ip.result.ip}:${data.external.get_rabbitmq_amqp_port.result.port}"
    dist  = "http://${data.external.get_rabbitmq_ip.result.ip}:${data.external.get_rabbitmq_dist_port.result.port}"
    stats = "http://${data.external.get_rabbitmq_ip.result.ip}:${data.external.get_rabbitmq_stats_port.result.port}"
  }
}
