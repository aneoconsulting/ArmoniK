output "armonik_control_plane" {
  description = "URL of ArmoniK control plane"
  value = module.armonik.control_plane_url
}

output "armonik_seq" {
  description = "URL of Seq"
  value = local.seq_endpoint_url
}

output "armonik_grafana" {
  description = "URL of Grafana"
  value = local.grafana_endpoint_url
}