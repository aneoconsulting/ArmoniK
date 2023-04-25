# Rabbitmq
output "host" {
  value = local.rabbitmq_endpoints.ip
}

output "port" {
  value = local.rabbitmq_endpoints.port
}

output "url" {
  value = local.rabbitmq_url
}

output "web_url" {
  value = local.rabbitmq_web_url
}

output "user_certificate" {
  description = "User certificates of rabbitmq"
  value = {
    secret    = kubernetes_secret.rabbitmq_client_certificate.metadata[0].name
    data_keys = keys(kubernetes_secret.rabbitmq_client_certificate.data)
  }
}

output "user_credentials" {
  description = "User credentials of rabbitmq"
  value = {
    secret    = kubernetes_secret.rabbitmq_user.metadata[0].name
    data_keys = keys(kubernetes_secret.rabbitmq_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of rabbitmq"
  value = {
    secret    = kubernetes_secret.rabbitmq.metadata[0].name
    data_keys = keys(kubernetes_secret.rabbitmq.data)
  }
}

output "protocol" {
  description = "Protocol of RabbitMQ"
  value       = var.rabbitmq.protocol
}