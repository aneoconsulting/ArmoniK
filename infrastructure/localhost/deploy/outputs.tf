# Storage
output "object_storage_endpoint_url" {
  value = "${module.storage.object_storage.spec.0.cluster_ip}:${module.storage.object_storage.spec.0.port.0.port}"
}

output "table_storage_endpoint_url" {
  value = "mongodb://${module.storage.table_storage.spec.0.cluster_ip}:${module.storage.table_storage.spec.0.port.0.port}"
}

output "shared_storage_pvc_name" {
  value = module.storage.shared_storage_persistent_volume_claim.metadata.0.name
}

output "shared_storage_pvc_size" {
  value = module.storage.shared_storage_persistent_volume_claim.spec.0.resources.0.requests.storage
}

output "queue_storage_endpoint_url" {
  value = [
  for port in module.storage.queue_storage.spec.0.port : {
    name         = port.name
    endpoint_url = "http://${module.storage.queue_storage.spec.0.cluster_ip}:${port.port}"
  }
  ]
}

# Armonik components
output "control_plane_internal_endpoint_url" {
  value = "${module.armonik.control_plane.spec.0.cluster_ip}:${module.armonik.control_plane.spec.0.port.0.port}"
}

output "control_plane_external_endpoint_url" {
  value = "${module.armonik.control_plane.status.0.load_balancer.0.ingress.0.ip}:${module.armonik.control_plane.spec.0.port.0.port}"
}

output "compute_plane" {
  value = [
  for container in module.armonik.compute_plane.0.spec.0.template.0.spec.0.container : {
    name           = container.name
    container_port = length(container.port) == 0 ? 0 : container.port.0.container_port
  }
  ]
}