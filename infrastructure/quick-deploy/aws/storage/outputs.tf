# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLS"
  value       = {
    activemq = {
      url     = module.mq.activemq_endpoint_url.url
      host    = module.mq.activemq_endpoint_url.host
      port    = module.mq.activemq_endpoint_url.port
      web_url = module.mq.web_url
    }
    redis    = {
      url  = module.elasticache.redis_endpoint_url.url
      host = module.elasticache.redis_endpoint_url.host
      port = module.elasticache.redis_endpoint_url.port
    }
    mongodb  = {
      url  = ""
      host = ""
      port = ""
    }
    shared   = {
      host       = ""
      secret     = ""
      kms_key_id = module.s3_fs.kms_key_id
      name       = module.s3_fs.s3_bucket_name
      # Path to external shared storage from which worker containers upload .dll
      host_path  = "/data"
    }
  }
}
