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
      host   = ""
      secret = ""
      id     = module.s3_bucket_fs.s3_bucket_name
      # Path to external shared storage from which worker containers upload .dll
      path   = "/data"
    }
  }
}
