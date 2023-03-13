# MongoDB
output "host" {
  description = "Hostname or IP address of MongoDB server"
  value       = local.mongodb_endpoints.ip
}

output "port" {
  description = "Port of MongoDB server"
  value       = local.mongodb_endpoints.port
}

output "url" {
  description = "Endpoint URL of MongoDB server"
  value       = local.mongodb_url
}

output "user_certificate" {
  description = "User certificates of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb_client_certificate.metadata[0].name
    data_keys = keys(kubernetes_secret.mongodb_client_certificate.data)
  }
}

output "user_credentials" {
  description = "User credentials of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb_user.metadata[0].name
    data_keys = keys(kubernetes_secret.mongodb_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb.metadata[0].name
    data_keys = keys(kubernetes_secret.mongodb.data)
  }
}
