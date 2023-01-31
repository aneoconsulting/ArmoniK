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

output "objects_storage_adapter_check" {
  value = var.object_storage_adapter
  precondition {
    condition     = contains(local.deployed_object_storages, var.object_storage_adapter)
    error_message = "can't use ${var.object_storage_adapter} because it has not been deployed. Deployed storages are : ${join(",", local.deployed_object_storages)}"
  }
}
