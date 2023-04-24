output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value = {
    object_storage_adapter   = local.object_storage_adapter
    table_storage_adapter    = local.table_storage_adapter
    queue_storage_adapter    = local.queue_storage_adapter
    deployed_object_storages = local.deployed_object_storages
    deployed_table_storages  = local.deployed_table_storages
    deployed_queue_storages  = local.deployed_queue_storages
    activemq = {
      url                   = module.activemq.url
      web_url               = module.activemq.web_url
      adapter_class_name    = module.activemq.adapter_class_name
      adapter_absolute_path = module.activemq.adapter_absolute_path
      engine_type           = module.activemq.engine_type
    }
    redis = length(module.redis) > 0 ? {
      url = module.redis[0].url
    } : null
    s3 = length(module.minio) > 0 ? {
      url         = try(module.minio[0].url, "")
      bucket_name = try(module.minio[0].bucket_name, "")
    } : null
    mongodb = {
      url                = module.mongodb.url
      number_of_replicas = var.mongodb.replicas_number
    }
    shared = local.shared_storage
  }
}
