# Armonik control palne
output "control_plane" {
  value = kubernetes_service.control_plane
}

# Armonik compute plane
output "compute_plane" {
  value = kubernetes_deployment.compute_plane
}