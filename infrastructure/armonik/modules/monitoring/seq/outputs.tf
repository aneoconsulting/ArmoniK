# Seq
output "url" {
  description = "URL of Seq"
  value = local.seq_url
}

output "port" {
  description = "Port of Seq"
  value = local.seq_endpoints.seq_port
}

output "host" {
  description = "Host of Seq"
  value = local.seq_endpoints.ip
}

output "web_url" {
  description = "Web URL of Seq"
  value = local.seq_web_url
}
