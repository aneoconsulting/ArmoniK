output "armonik_deployment" {
  description = "ArmoniK control plane URL"
  value       = {
    armonik_control_plane_url = module.armonik.control_plane_url
    seq_web_url               = module.seq.web_url
  }
}


