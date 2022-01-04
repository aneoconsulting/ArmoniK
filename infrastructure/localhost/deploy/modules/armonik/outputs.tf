# Armonik control palne
output "control_plane" {
  value = kubernetes_service.control_plane
}

# Seq
output "seq" {
  value = kubernetes_service.seq
}

# Armonik compute plane
output "compute_plane" {
  value = kubernetes_deployment.compute_plane
}