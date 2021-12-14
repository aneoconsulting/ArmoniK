locals {
  # To lower
  allowed_storage = {
    object_storage         = [for type in local.storage.allowed_object_storage : lower(type)]
    table_storage          = [for type in local.storage.allowed_table_storage : lower(type)]
    queue_storage          = [for type in local.storage.allowed_queue_storage : lower(type)]
    lease_provider_storage = [for type in local.storage.allowed_lease_provider_storage : lower(type)]
  }

  # Needed resource for each storage
  needed_storage = {
    object_storage         = (contains(local.allowed_storage.object_storage, lower(var.armonik.storage_services.object_storage_type)) ? lower(var.armonik.storage_services.object_storage_type) : "mongodb")
    table_storage          = (contains(local.allowed_storage.table_storage, lower(var.armonik.storage_services.table_storage_type)) ? lower(var.armonik.storage_services.table_storage_type) : "mongodb")
    queue_storage          = (contains(local.allowed_storage.queue_storage, lower(var.armonik.storage_services.queue_storage_type)) ? lower(var.armonik.storage_services.queue_storage_type) : "mongodb")
    lease_provider_storage = (contains(local.allowed_storage.lease_provider_storage, lower(var.armonik.storage_services.lease_provider_storage_type)) ? lower(var.armonik.storage_services.lease_provider_storage_type) : "mongodb")
  }

  # List of resources to deploy
  list_of_storage = distinct([
    local.needed_storage.object_storage,
    local.needed_storage.table_storage,
    local.needed_storage.queue_storage,
    local.needed_storage.lease_provider_storage,
    "redis"
  ])

  # Setting of ArmoniK storage services
  storage_services = {
    object_storage_type         = (local.needed_storage.object_storage == "redis" ? "Redis.ObjectStorage" : "MongoDB.ObjectStorage")
    table_storage_type          = "MongoDB.TableStorage"
    queue_storage_type          = (local.needed_storage.queue_storage == "amqp" ? "Amqp.QueueStorage" : "MongoDB.LockedQueueStorage")
    lease_provider_storage_type = "MongoDB.LeaseProvider"
    resources                   = {
      mongodb_endpoint_url  = (contains(local.list_of_storage, "mongodb") ? "mongodb://${module.mongodb.0.storage.spec.0.cluster_ip}:${module.mongodb.0.storage.spec.0.port.0.port}" : "")
      redis_endpoint_url    = (contains(local.list_of_storage, "redis") ? "${module.redis.0.storage.spec.0.cluster_ip}:${module.redis.0.storage.spec.0.port.0.port}" : "")
      activemq_endpoint_url = (contains(local.list_of_storage, "amqp") ? "amqp://${module.activemq.0.storage.spec.0.cluster_ip}:${module.activemq.0.storage.spec.0.port.0.port}" : "")
    }
  }
}