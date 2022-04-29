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

output "web_host" {
  value = local.activemq_endpoints.ip
}

output "web_port" {
  value = local.activemq_endpoints.web_port
}

output "user_certificate" {
  description = "User certificates of ActiveMQ"
  value       = {
    secret      = kubernetes_secret.activemq_client_certificate.metadata[0].name
    ca_filename = "chain.pem"
  }
}

output "user_credentials" {
  description = "User credentials of ActiveMQ"
  value       = {
    secret       = kubernetes_secret.activemq_user.metadata[0].name
    username_key = "username"
    password_key = "password"
  }
}

output "admin_credentials" {
  description = "Admin credentials of ActiveMQ"
  value       = {
    secret       = kubernetes_secret.activemq_admin.metadata[0].name
    username_key = "username"
    password_key = "password"
  }
}

output "trigger_authentication" {
  description = "Keda trigger authentication for ActiveMQ"
  value       = "trigger-auth-activemq"
}