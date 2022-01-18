output "armonik_control_plane" {
  value = module.armonik.control_plane_url
}

output "armonik_seq" {
  value = (var.monitoring.seq ? module.seq.0.seq_web_url : "")
}

output "armonik_grafana" {
  value = (var.monitoring.grafana ? module.grafana.0.grafana_url : "")
}

output "armonik_prometheus" {
  value = (var.monitoring.prometheus ? module.prometheus.0.prometheus_url : "")
}