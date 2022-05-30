output "endpoint_urls" {
  value = var.ingress != null ? {
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = local.grafana_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : local.grafana_url) : ""
    seq_web_url       = local.seq_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : local.seq_web_url) : ""
    admin_api_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/api" : local.admin_api_url
    admin_app_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/" : local.admin_app_url
  } : {
    control_plane_url = local.control_plane_url
    grafana_url       = local.grafana_url
    seq_web_url       = local.seq_web_url
    admin_api_url     = local.admin_api_url
    admin_app_url     = local.admin_app_url
  }
}
