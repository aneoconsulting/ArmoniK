output "endpoint_urls" {
  value = var.ingress != null ? {
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = data.kubernetes_secret.grafana.data.enabled ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : nonsensitive(data.kubernetes_secret.grafana.data.url)) : ""
    seq_web_url       = data.kubernetes_secret.seq.data.enabled ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : nonsensitive(data.kubernetes_secret.seq.data.web_url)) : ""
    admin_api_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/api" : local.admin_api_url
    admin_app_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/" : local.admin_app_url
    } : {
    control_plane_url = local.control_plane_url
    grafana_url       = nonsensitive(data.kubernetes_secret.grafana.data.url)
    seq_web_url       = nonsensitive(data.kubernetes_secret.seq.data.web_url)
    admin_api_url     = local.admin_api_url
    admin_app_url     = local.admin_app_url
  }
}


output "control_plane_url" {
  description = <<-EOT
    [DEPRECATED] Endpoint URL of ArmoniK control plane
    use endpoint_urls instead
  EOT
  value       = local.control_plane_url
}
# Armonik admin API
output "admin_api_url" {
  description = "Endpoint URL of ArmoniK admin API"
  value       = local.admin_api_url
}
# Armonik admin App
output "admin_app_url" {
  description = "Endpoint URL of ArmoniK admin App"
  value       = local.admin_app_url
}

output "ingress_DEPRECATED" {
  description = "deprecation notice for `ingress` output"
  value       = "`ingress` is deprecated. Please use `endpoint_urls` directly."
}
output "ingress" {
  description = <<-EOT
    [DEPRECATED] ingress endpoint
    use endpoint_urls instead
  EOT
  value = var.ingress != null ? {
    http              = local.ingress_http_url
    grpc              = local.ingress_grpc_url
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = data.kubernetes_secret.grafana.data.enabled ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : data.kubernetes_secret.grafana.data.url) : ""
    seq_web_url       = data.kubernetes_secret.seq.data.enabled ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : data.kubernetes_secret.seq.data.web_url) : ""
    admin_api_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/api" : local.admin_api_url
    admin_app_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/" : local.admin_app_url
    } : {
    http              = ""
    grpc              = ""
    control_plane_url = local.control_plane_url
    grafana_url       = data.kubernetes_secret.grafana.data.url
    seq_web_url       = data.kubernetes_secret.seq.data.web_url
    admin_api_url     = local.admin_api_url
    admin_app_url     = local.admin_app_url
  }
}
