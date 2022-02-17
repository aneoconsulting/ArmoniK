# Armonik control plane
output "control_plane" {
  value = kubernetes_service.control_plane
}

output "control_plane_url" {
  value = local.control_plane_url
}

# Armonik compute plane
output "compute_plane" {
  value = kubernetes_deployment.compute_plane
}