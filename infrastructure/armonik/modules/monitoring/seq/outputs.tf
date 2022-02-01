# Seq
output "seq" {
  value = kubernetes_service.seq
}

output "seq_endpoints" {
  value = {
    url  = local.seq_url
    host = local.seq_endpoints.ip
    port = local.seq_endpoints.seq_port
  }
}

output "seq_web_url" {
  value = local.seq_web_url
}
