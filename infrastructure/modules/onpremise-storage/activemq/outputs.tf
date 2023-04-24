# ActiveMQ
output "host" {
  value = local.activemq_endpoints.ip
}

output "port" {
  value = local.activemq_endpoints.port
}

output "url" {
  value = local.activemq_url
}

output "web_url" {
  value = local.activemq_web_url
}

output "user_certificate" {
  description = "User certificates of ActiveMQ"
  value = {
    secret    = kubernetes_secret.activemq_client_certificate.metadata[0].name
    data_keys = keys(kubernetes_secret.activemq_client_certificate.data)
  }
}

output "user_credentials" {
  description = "User credentials of ActiveMQ"
  value = {
    secret    = kubernetes_secret.activemq_user.metadata[0].name
    data_keys = keys(kubernetes_secret.activemq_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of ActiveMQ"
  value = {
    secret    = kubernetes_secret.activemq.metadata[0].name
    data_keys = keys(kubernetes_secret.activemq.data)
  }
}

output "engine_type" {
  description = "Engine type"
  value       = "ActiveMQ"
}

output "adapter_class_name" {
  description = "Class name for queue adapter"
  value       = "ArmoniK.Core.Adapters.Amqp.QueueBuilder"
}

output "adapter_absolute_path" {
  description = "Absolute path for the queue adapter"
  value       = "/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"
}