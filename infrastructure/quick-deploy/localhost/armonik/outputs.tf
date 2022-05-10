output "armonik" {
  description = "ArmoniK endpoint URL"
  value       = {
    control_plane_url = module.armonik.control_plane_url
    ingress           = module.armonik.ingress
  }
}
