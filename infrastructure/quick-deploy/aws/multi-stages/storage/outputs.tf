# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value       = {
    object_storage_adapter   = local.object_storage_adapter
    table_storage_adapter    = local.table_storage_adapter
    queue_storage_adapter    = local.queue_storage_adapter
    deployed_object_storages = local.deployed_object_storages
    deployed_table_storages  = local.deployed_table_storages
    deployed_queue_storages  = local.deployed_queue_storages
    activemq                 = {
      url     = module.mq.activemq_endpoint_url.url
      web_url = module.mq.web_url
    }
    redis = length(module.elasticache) > 0 ? {
      url = module.elasticache[0].redis_endpoint_url.url
    } : null
    s3 = length(module.s3_os) > 0 ? {
      url                   = "https://s3.${var.region}.amazonaws.com"
      bucket_name           = module.s3_os[0].s3_bucket_name
      must_force_path_style = false
      kms_key_id            = module.s3_os[0].kms_key_id
    } : null
    /*mongodb = {
      url                = module.mongodb.url
      number_of_replicas = var.mongodb.replicas_number
    }*/
    mongodb = {
      cluster_name        = module.mongodb.cluster_name
      endpoint            = module.mongodb.endpoint
      master_host         = module.mongodb.master_host
      master_port         = 27017
      master_password     = module.mongodb.master_password
      master_username     = module.mongodb.master_username
      reader_endpoint     = module.mongodb.reader_endpoint
      replicas_host       = module.mongodb.replicas_host
      security_group_id   = module.mongodb.security_group_id
      security_group_name = module.mongodb.security_group_name
    }
    shared = {
      service_url       = "https://s3.${var.region}.amazonaws.com"
      kms_key_id        = module.s3_fs.kms_key_id
      name              = module.s3_fs.s3_bucket_name
      file_storage_type = "S3"
    }
  }
  sensitive = true
}
