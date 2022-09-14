# Seq
output "url" {
  description = "URL of Seq"
  value       = local.seq_url
}

output "port" {
  description = "Port of Seq"
  value       = kubernetes_service.seq.spec.0.port.0.port
}

output "host" {
  description = "Host of Seq"
  value       = kubernetes_service.seq.spec.0.cluster_ip
}

output "web_url" {
  description = "Web URL of Seq"
  value       = local.seq_web_url
}
