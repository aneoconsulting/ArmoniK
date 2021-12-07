# Storage
# MongoDB
module "mongodb" {
  source    = "./modules/storage/mongodb"
  namespace = var.namespace
  mongodb   = var.mongodb
}

# Local shared storage
module "local_shared_storage" {
  source               = "./modules/storage/local-shared-storage"
  namespace            = var.namespace
  local_shared_storage = var.local_shared_storage
}

# ArmoniK components
module "armonik" {
  source       = "./modules/armonik"
  namespace    = var.namespace
  max_priority = var.max_priority
  depends_on   = [module.mongodb]

  armonik = {
    control_plane    = var.armonik.control_plane
    compute_plane    = var.armonik.compute_plane
    storage_services = {
      object_storage         = {
        type = var.armonik.storage_services.object_storage_type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      table_storage          = {
        type = var.armonik.storage_services.table_storage_type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      queue_storage          = {
        type = var.armonik.storage_services.queue_storage_type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      lease_provider_storage = {
        type = var.armonik.storage_services.lease_provider_storage_type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      shared_storage         = {
        claim_name  = module.local_shared_storage.shared_storage_persistent_volume_claim.metadata.0.name
        target_path = var.armonik.storage_services.shared_storage_target_path
      }
    }
  }
}