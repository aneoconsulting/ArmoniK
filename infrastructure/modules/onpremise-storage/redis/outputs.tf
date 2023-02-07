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
  value = {
    secret    = kubernetes_secret.redis_client_certificate.metadata[0].name
    data_keys = keys(kubernetes_secret.redis_client_certificate.data)
  }
}

output "user_credentials" {
  description = "User credentials of Redis"
  value = {
    secret    = kubernetes_secret.redis_user.metadata[0].name
    data_keys = keys(kubernetes_secret.redis_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of redis"
  value = {
    secret    = kubernetes_secret.redis.metadata[0].name
    data_keys = keys(kubernetes_secret.redis.data)
  }
}