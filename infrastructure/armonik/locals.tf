# Needed storage
module "storage" {
  source  = "../modules/needed-storage"
  storage = var.storage
}

# Use Seq
module "seq" {
  source    = "./modules/seq"
  count     = (var.seq.use ? 1 : 0)
  namespace = var.seq.namespace
}

locals {
  # Storage adapters
  storage_adapters = {
    object         = (module.storage.needed_storage.object == "redis" ? "Redis.ObjectStorage" : "MongoDB.ObjectStorage")
    table          = "MongoDB.TableStorage"
    queue          = (module.storage.needed_storage.queue == "amqp" ? "Amqp.QueueStorage" : "MongoDB.LockedQueueStorage")
    lease_provider = "MongoDB.LeaseProvider"
  }

  storage = {
    list      = module.storage.list_storage
    data_type = module.storage.needed_storage
  }

  seq_endpoint_url = (var.seq.use ? module.seq.0.seq_url : "")
}