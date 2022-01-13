# Armonik control plane
output "control_plane" {
  value = kubernetes_service.control_plane
}

output "control_plane_url" {
  value = local.control_plane_url
}

# Seq
output "seq" {
  value = kubernetes_service.seq
}

output "seq_url" {
  value = local.seq_url
}

output "seq_web_url" {
  value = local.seq_web_url
}

# Armonik compute plane
output "compute_plane" {
  value = kubernetes_deployment.compute_plane
}