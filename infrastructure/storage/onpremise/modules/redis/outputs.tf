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