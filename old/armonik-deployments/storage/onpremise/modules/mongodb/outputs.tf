# MongoDB
output "host" {
  value = local.mongodb_endpoints.ip
}

output "port" {
  value = local.mongodb_endpoints.port
}

output "url" {
  value = local.mongodb_url
}