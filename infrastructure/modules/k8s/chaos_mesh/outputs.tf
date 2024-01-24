output "chaos_mesh_url" {
  description = "Chaos Mesh endpoint URL"
  value       = "http://${data.kubernetes_service.chaos_dashboard.status.0.load_balancer.0.ingress.0.ip}:${data.kubernetes_service.chaos_dashboard.spec.0.port.0.node_port}"
}
