output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value = {
    activemq = {
      url     = module.activemq.url
      web_url = module.activemq.web_url
    }
    redis = {
      url = module.redis.url
    }
    s3 = {
      url         = try(module.minio[0].url, "")
      bucket_name = try(module.minio[0].bucket_name, "")
    }
    deployed_object_storages = var.object_storages_to_be_deployed
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
