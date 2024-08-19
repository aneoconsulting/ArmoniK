output "armonik" {
  description = "ArmoniK endpoint URL"
  value = {
    control_plane_url = module.armonik.endpoint_urls.control_plane_url
    grafana_url       = module.armonik.endpoint_urls.grafana_url
    seq_web_url       = module.armonik.endpoint_urls.seq_web_url
    admin_app_url     = module.armonik.endpoint_urls.admin_app_url
    chaos_mesh_url    = one(module.chaos_mesh[*].chaos_mesh_url)
  }
}
