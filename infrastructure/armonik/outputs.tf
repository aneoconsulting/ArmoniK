output "armonik_control_plane" {
  value = "http://${module.armonik.control_plane.status.0.load_balancer.0.ingress.0.ip}:${module.armonik.control_plane.spec.0.port.0.port}"
}