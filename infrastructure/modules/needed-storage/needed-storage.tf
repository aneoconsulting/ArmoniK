locals {
  # To lower
  lower_allowed_storage = {
    object         = [for resource_name in local.allowed_storage.object : lower(resource_name)]
    table          = [for resource_name in local.allowed_storage.table : lower(resource_name)]
    queue          = [for resource_name in local.allowed_storage.queue : lower(resource_name)]
    lease_provider = [for resource_name in local.allowed_storage.lease_provider : lower(resource_name)]
    shared         = [for resource_name in local.allowed_storage.shared : lower(resource_name)]
  }

  lower_list_adapted_storage = [for resource_name in local.list_adapted_storage : lower(resource_name)]

  # Needed resource for each storage
  needed_storage = (try({
    object         = var.storage.object == "" ? "" : (contains(local.lower_allowed_storage.object, lower(var.storage.object)) ? lower(var.storage.object) : "redis")
    table          = var.storage.table == "" ? "" : (contains(local.lower_allowed_storage.table, lower(var.storage.table)) ? lower(var.storage.table) : "mongodb")
    queue          = var.storage.queue == "" ? "" : (contains(local.lower_allowed_storage.queue, lower(var.storage.queue)) ? lower(var.storage.queue) : "Amqp")
    lease_provider = var.storage.lease_provider == "" ? "" : (contains(local.lower_allowed_storage.lease_provider, lower(var.storage.lease_provider)) ? lower(var.storage.lease_provider) : "mongodb")
    shared         = var.storage.shared == "" ? "" : (contains(local.lower_allowed_storage.shared, lower(var.storage.shared)) ? lower(var.storage.shared) : "HostPath")
  }, [for resource_name in var.storage : (contains(local.lower_list_adapted_storage, lower(resource_name)) ? lower(resource_name) : "")]))

  # List of resources to deploy
  list_storage = (compact(try(distinct([
    local.needed_storage.object,
    local.needed_storage.table,
    local.needed_storage.queue,
    local.needed_storage.lease_provider,
    local.needed_storage.shared,
  ]), distinct(local.needed_storage))))
}