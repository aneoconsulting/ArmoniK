output "armonik" {
  description = "ArmoniK endpoint URL"
  value       = module.armonik.control_plane_url
}

output "ingress" {
  value = module.armonik.ingress
}
