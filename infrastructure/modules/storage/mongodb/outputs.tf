# MongoDB
output "service" {
  value = kubernetes_service.mongodb
}

output "deployment" {
  value = kubernetes_deployment.mongodb
}