# Storage
# MongoDB
module "mongodb" {
  count     = (contains(local.list_of_storage, "mongodb") ? 1 : 0)
  source    = "./modules/storage/mongodb"
  namespace = var.namespace
  mongodb   = var.mongodb
}

# Redis
module "redis" {
  count     = (contains(local.list_of_storage, "redis") ? 1 : 0)
  source    = "./modules/storage/redis"
  namespace = var.namespace
  redis     = var.redis
}

# ActiveMQ
module "activemq" {
  count     = (contains(local.list_of_storage, "activemq") ? 1 : 0)
  source    = "./modules/storage/activemq"
  namespace = var.namespace
  activemq  = var.activemq
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
      object_storage         = local.storage_services.object_storage
      table_storage          = local.storage_services.table_storage
      queue_storage          = local.storage_services.queue_storage
      lease_provider_storage = local.storage_services.lease_provider_storage
      shared_storage         = {
        claim_name  = module.local_shared_storage.shared_storage_persistent_volume_claim.metadata.0.name
        target_path = var.armonik.storage_services.shared_storage_target_path
      }
    }
  }
}