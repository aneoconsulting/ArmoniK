output "endpoint_urls" {
  value = var.ingress != null ? {
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = local.grafana_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : local.grafana_url) : ""
    seq_web_url       = local.seq_web_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : local.seq_web_url) : ""
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
    grafana_url       = local.grafana_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : local.grafana_url) : ""
    seq_web_url       = local.seq_web_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : local.seq_web_url) : ""
    admin_api_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/api" : local.admin_api_url
    admin_app_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/" : local.admin_app_url
    } : {
    http              = ""
    grpc              = ""
    control_plane_url = local.control_plane_url
    grafana_url       = local.grafana_url
    seq_web_url       = local.seq_web_url
    admin_api_url     = local.admin_api_url
    admin_app_url     = local.admin_app_url
  }
}

output "objects_storage_adapter_check"{
  value = var.object_storage_adapter
  precondition  {
    condition       = contains(local.deployed_object_storages, var.object_storage_adapter)
    error_message   = "can't use ${var.object_storage_adapter} because it has not been deployed. Deployed storages are : ${join(",", local.deployed_object_storages)}"
  }
}