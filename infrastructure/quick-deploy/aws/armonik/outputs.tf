output "armonik" {
  description = "ArmoniK endpoint URL"
  value = {
    control_plane_url = module.armonik.control_plane_url
    admin_app_url     = module.armonik.admin_app_url
    admin_api_url     = module.armonik.admin_api_url
    ingress           = module.armonik.ingress
  }
}

