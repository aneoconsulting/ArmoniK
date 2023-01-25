# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value = {
    activemq = {
      url          = module.mq.activemq_endpoint_url.url
      web_url      = module.mq.web_url
      credentials  = local.mq_user_credentials
      certificates = null
      endpoints    = local.mq_endpoints
    }
    redis = {
      url          = module.elasticache.redis_endpoint_url.url
      credentials  = null
      certificates = null
      endpoints    = local.elasticache_endpoints
    }
    mongodb = {
      url          = module.mongodb.url
      credentials  = module.mongodb.user_credentials
      certificates = module.mongodb.user_certificate
      endpoints    = module.mongodb.endpoints
    }
    shared = local.shared_storage_endpoints
  }
  sensitive = true
}
