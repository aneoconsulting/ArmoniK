# Storage
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
      url     = module.mq.endpoint_url
      web_url = module.mq.web_url
    }
    redis = length(module.elasticache) > 0 ? {
      url = module.elasticache[0].endpoint_url
    } : null
    s3 = length(module.s3_os) > 0 ? {
      url                   = "https://s3.${var.region}.amazonaws.com"
      bucket_name           = module.s3_os[0].s3_bucket_name
      must_force_path_style = false
      kms_key_id            = module.s3_os[0].kms_key_id
    } : null
    mongodb = {
      url                = module.mongodb.url
      number_of_replicas = var.mongodb.replicas_number
    }
    shared = {
      service_url       = "https://s3.${var.region}.amazonaws.com"
      kms_key_id        = module.s3_fs.kms_key_id
      name              = module.s3_fs.s3_bucket_name
      file_storage_type = "S3"
    }
  }
}
