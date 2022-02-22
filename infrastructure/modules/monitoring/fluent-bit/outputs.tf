output "container_name" {
  description = "Container name of Fluent-bit"
  value       = var.fluent_bit.container_name
}

output "image" {
  description = "image of Fluent-bit"
  value       = var.fluent_bit.image
}

output "tag" {
  description = "tag of Fluent-bit"
  value       = var.fluent_bit.tag
}

output "is_daemonset" {
  description = "Is Fluent-bit a daemonset"
  value       = var.fluent_bit.is_daemonset
}

output "configmaps" {
  description = "Configmaps of Fluent-bit"
  value       = {
    envvars = kubernetes_config_map.fluent_bit_envvars_config.metadata.0.name
    config  = kubernetes_config_map.fluent_bit_config.metadata.0.name
  }
}