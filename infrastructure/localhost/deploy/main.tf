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
  count     = (contains(local.list_of_storage, "amqp") ? 1 : 0)
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
  seq          = var.seq
  armonik      = {
    control_plane    = var.armonik.control_plane
    compute_plane    = var.armonik.compute_plane
    storage_services = {
      object_storage_type         = local.storage_services.object_storage_type
      table_storage_type          = local.storage_services.table_storage_type
      queue_storage_type          = local.storage_services.queue_storage_type
      lease_provider_storage_type = local.storage_services.lease_provider_storage_type
      external_storage_types      = distinct(local.needed_storage.external_storage)
      resources                   = local.storage_services.resources
      shared_storage              = {
        claim_name  = module.local_shared_storage.shared_storage_persistent_volume_claim.metadata.0.name
        target_path = var.armonik.storage_services.shared_storage_target_path
      }
    }
    secrets          = local.secrets
  }
}