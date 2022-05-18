output "endpoint_urls" {
  value = var.ingress != null ? {
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = local.grafana_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : local.grafana_url) : ""
    seq_web_url       = local.seq_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : local.seq_web_url) : ""
  } : {
    control_plane_url = local.control_plane_url
    grafana_url       = local.grafana_url
    seq_web_url       = local.seq_web_url
  }
}