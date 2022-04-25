# Armonik control plane
output "control_plane_url" {
  description = "Endpoint URL of ArmoniK control plane"
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
