output "agent_config" {
  description = "file name for the agent configuration"
  value       = abspath(local_file.agent_config_file.filename)
}

output "redis_url" {
  value = "${module.control_plane.redis_pod_ip}:${var.redis_port}"
}

output "mongodb_url" {
  value = "mongodb://${module.control_plane.mongodb_pod_ip}:${var.mongodb_port}"
}

output "queue_url" {
  value = "${module.control_plane.queue_pod_ip}:${var.queue_port}"
}

output "private_nginx_url" {
  value = "http://${module.control_plane.ngnix_pod_ip}:${var.nginx_port}"
}

output "public_nginx_url" {
  value = "http://${module.control_plane.ngnix_pod_external_ip}:${var.nginx_port}"
}