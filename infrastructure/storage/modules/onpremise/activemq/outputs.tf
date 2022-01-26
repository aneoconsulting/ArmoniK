# ActiveMQ
output "service" {
  value = kubernetes_service.activemq
}

output "deployment" {
  value = kubernetes_deployment.activemq
}