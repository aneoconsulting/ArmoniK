# Needed storage
module "storage" {
  source  = "../modules/needed-storage"
  storage = var.storage
}

locals {
  # Storage adapters
  storage_adapters = {
    object         = (module.storage.needed_storage.object == "redis" ? "Redis.ObjectStorage" : "MongoDB.ObjectStorage")
    table          = "MongoDB.TableStorage"
    queue          = (module.storage.needed_storage.queue == "amqp" ? "Amqp.QueueStorage" : "MongoDB.LockedQueueStorage")
    lease_provider = "MongoDB.LeaseProvider"
  }
}