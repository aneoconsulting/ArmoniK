# Armonik control plane
output "control_plane_url" {
  description = "Endpoint URL of ArmoniK control plane"
  value       = local.control_plane_url
}

output "ingress" {
  description = "ingress endpoint"
  value = {
    http = local.ingress_http_url
    grpc = local.ingress_grpc_url
    control_plane = local.ingress_grpc_url != "" ? "${local.ingress_grpc_url}/" : local.control_plane_url
    grafana = local.grafana_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : local.grafana_url) : ""
    seq = local.seq_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : local.seq_web_url) : ""
  }
}
