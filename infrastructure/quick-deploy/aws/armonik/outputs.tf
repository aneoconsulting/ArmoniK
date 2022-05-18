output "armonik" {
  description = "ArmoniK endpoint URL"
  value       = {
    control_plane_url = module.armonik.endpoint_urls.control_plane_url
    grafana_url       = try(var.monitoring.grafana.url, module.armonik.endpoint_urls.grafana_url)
    seq_web_url       = try(var.monitoring.seq.web_url, module.armonik.endpoint_urls.seq_web_url)
  }
}

