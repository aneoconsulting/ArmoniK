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
      url     = module.activemq.url
      web_url = module.activemq.web_url
    }
    redis = {
      url = try(module.redis[0].url, "")
    }
    s3 = {
      url         = try(module.minio[0].url, "")
      bucket_name = try(module.minio[0].bucket_name, "")
    }
    mongodb = {
      url = module.mongodb.url
    }
    shared = {
      host_path         = local.shared_storage_host_path
      file_storage_type = local.shared_storage_file_storage_type
      file_server_ip    = local.shared_storage_file_server_ip
    }
  }
}
