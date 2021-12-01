# Armonik control palne
output "control_plane" {
  value = kubernetes_service.control_plane
}

# Armonik agent
output "agent" {
  value = kubernetes_deployment.agent
}