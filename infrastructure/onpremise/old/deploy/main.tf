# Storage
# MongoDB
module "mongodb" {
  source    = "modules/storage/mongodb"
  namespace = var.namespace
  mongodb   = var.mongodb
}

# NFS storage
module "nfs_storage" {
  source    = "modules/storage/nfs"
  namespace = var.namespace
  nfs       = var.nfs
}

# ArmoniK components
module "armonik" {
  source     = "modules/armonik"
  namespace  = var.namespace
  priority   = var.priority
  depends_on = [module.mongodb]

  armonik = {
    control_plane    = var.armonik.control_plane
    compute_plane    = var.armonik.compute_plane
    storage_services = {
      object_storage         = {
        type = var.armonik.storage_services.object_storage.type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      table_storage          = {
        type = var.armonik.storage_services.table_storage.type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      queue_storage          = {
        type = var.armonik.storage_services.queue_storage.type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      lease_provider_storage = {
        type = var.armonik.storage_services.lease_provider_storage.type
        url  = module.mongodb.storage.spec.0.cluster_ip
        port = module.mongodb.storage.spec.0.port.0.port
      }
      shared_storage         = {
        claim_name  = module.nfs_storage.nfs_storage_persistent_volume_claim.metadata.0.name
        target_path = var.armonik.storage_services.shared_storage.target_path
      }
    }
  }
}