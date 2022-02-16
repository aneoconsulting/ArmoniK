# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value       = {
    activemq = {
      url                 = module.activemq.url
      host                = module.activemq.host
      port                = module.activemq.port
      web_url             = module.activemq.web_url
      credentials         = {
        secret       = module.activemq.user_credentials.secret
        username_key = module.activemq.user_credentials.username_key
        password_key = module.activemq.user_credentials.password_key
      }
      certificates        = {
        secret      = module.activemq.user_certificate.secret
        ca_filename = module.activemq.user_certificate.ca_filename
      }
      allow_host_mismatch = true
    }
    redis    = {
      url          = module.redis.url
      host         = module.redis.host
      port         = module.redis.port
      credentials  = {
        secret       = module.redis.user_credentials.secret
        username_key = module.redis.user_credentials.username_key
        password_key = module.redis.user_credentials.password_key
      }
      certificates = {
        secret      = module.redis.user_certificate.secret
        ca_filename = module.redis.user_certificate.ca_filename
      }
      timeout      = 3000
      ssl_host     = "127.0.0.1"
    }
    mongodb  = {
      url                = module.mongodb.url
      host               = module.mongodb.host
      port               = module.mongodb.port
      credentials        = {
        secret       = module.mongodb.user_credentials.secret
        username_key = module.mongodb.user_credentials.username_key
        password_key = module.mongodb.user_credentials.password_key
      }
      certificates       = {
        secret      = module.mongodb.user_certificate.secret
        ca_filename = module.mongodb.user_certificate.ca_filename
      }
      allow_insecure_tls = true
    }
    shared   = {
      host_path         = var.shared_storage.host_path
      file_storage_type = var.shared_storage.file_storage_type
      file_server_ip    = var.shared_storage.file_server_ip
    }
  }
}
