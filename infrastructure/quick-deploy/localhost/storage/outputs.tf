output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value = {
    activemq = {
      url          = module.activemq.url
      web_url      = module.activemq.web_url
      credentials  = module.activemq.user_credentials
      certificates = module.activemq.user_certificate
      endpoints    = module.activemq.endpoints
    }
    redis = {
      url          = module.redis.url
      credentials  = module.redis.user_credentials
      certificates = module.redis.user_certificate
      endpoints    = module.redis.endpoints
    }
    mongodb = {
      url          = module.mongodb.url
      credentials  = module.mongodb.user_credentials
      certificates = module.mongodb.user_certificate
      endpoints    = module.mongodb.endpoints
    }
    shared = local.shared_storage
  }
  sensitive = true
}
