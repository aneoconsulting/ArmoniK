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