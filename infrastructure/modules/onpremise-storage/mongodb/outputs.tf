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
    secret      = kubernetes_secret.mongodb_client_certificate.metadata[0].name
    ca_filename = keys(kubernetes_secret.mongodb_client_certificate.data)[0]
  }
}

output "user_credentials" {
  description = "User credentials of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb_user.metadata[0].name
    data_keys = [for key, value in kubernetes_secret.mongodb_user.data : key]
  }
}

output "endpoints" {
  description = "Endpoints of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb_endpoints.metadata[0].name
    data_keys = [for key, value in kubernetes_secret.mongodb_endpoints.data : key]
  }
}
