# Seq
output "seq" {
  value = kubernetes_service.seq
}

output "seq_url" {
  value = local.seq_url
}

output "seq_web_url" {
  value = local.seq_web_url
}
