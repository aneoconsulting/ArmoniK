output "armonik_control_plane" {
  value = module.armonik.control_plane_url
}

output "armonik_seq" {
  value = (var.seq.use ? module.seq.0.seq_web_url : "")
}