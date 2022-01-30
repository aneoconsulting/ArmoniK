output "armonik_control_plane" {
  value = module.armonik.control_plane_url
}

output "armonik_seq" {
  value = local.seq_endpoint_url
}

output "armonik_grafana" {
  value = local.grafana_endpoint_url
}

output "armonik_prometheus" {
  value = local.prometheus_endpoint_url
}