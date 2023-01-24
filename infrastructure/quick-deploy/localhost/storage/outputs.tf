output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value = {
    activemq = {
      web_url      = module.activemq.web_url
      credentials  = module.activemq.user_credentials
      certificates = module.activemq.user_certificate
      endpoints    = module.activemq.endpoints
    }
    redis = {
      credentials  = module.redis.user_credentials
      certificates = module.redis.user_certificate
      endpoints    = module.redis.endpoints
    }
    mongodb = {
      credentials  = module.mongodb.user_credentials
      certificates = module.mongodb.user_certificate
      endpoints    = module.mongodb.endpoints
    }
    shared = {
      host_path         = local.shared_storage_host_path
      file_storage_type = local.shared_storage_file_storage_type
      file_server_ip    = local.shared_storage_file_server_ip
    }
  }
  sensitive = true
}
