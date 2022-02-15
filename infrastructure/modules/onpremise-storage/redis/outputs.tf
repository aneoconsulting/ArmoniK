# Redis
output "host" {
  value = local.redis_endpoints.ip
}

output "port" {
  value = local.redis_endpoints.port
}

output "url" {
  value = local.redis_url
}

output "user_certificate" {
  description = "User certificates of Redis"
  value       = {
    secret = kubernetes_secret.redis_client_certificate.metadata[0].name
    ca_filename = "chain.pem"
  }
}

output "user_credentials" {
  description = "User credentials of Redis"
  value       = {
    secret       = kubernetes_secret.redis_user.metadata[0].name
    username_key = "username"
    password_key = "password"
  }
}