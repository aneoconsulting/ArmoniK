# Storage
module "storage" {
  source    = "./storage"
  namespace = var.namespace

  # Object storage : Redis
  object_storage = var.object_storage

  # Table storage : MongoDB
  table_storage = var.table_storage

  # Queue storage : ActiveMQ
  queue_storage = var.queue_storage

  # Shared storage (like NFS)
  shared_storage = var.shared_storage
}

# ArmoniK components
module "armonik" {
  source     = "./armonik"
  namespace  = var.namespace
  depends_on = [module.storage]

  armonik = {
    control_plane    = var.armonik.control_plane
    compute_plane    = var.armonik.compute_plane
    storage_services = {
      object_storage         = {
        type = var.armonik.storage_services.object_storage.type
        url  = module.storage.table_storage.spec.0.cluster_ip
        port = module.storage.table_storage.spec.0.port.0.port
      }
      table_storage          = {
        type = var.armonik.storage_services.table_storage.type
        url  = module.storage.table_storage.spec.0.cluster_ip
        port = module.storage.table_storage.spec.0.port.0.port
      }
      queue_storage          = {
        type = var.armonik.storage_services.queue_storage.type
        url  = module.storage.table_storage.spec.0.cluster_ip
        port = module.storage.table_storage.spec.0.port.0.port
      }
      lease_provider_storage = {
        type = var.armonik.storage_services.lease_provider_storage.type
        url  = module.storage.table_storage.spec.0.cluster_ip
        port = module.storage.table_storage.spec.0.port.0.port
      }
      shared_storage         = {
        claim_name  = module.storage.shared_storage_persistent_volume_claim.metadata.0.name
        target_path = var.armonik.storage_services.shared_storage.target_path
      }
    }
  }
}
