# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value = {
    activemq = {
      web_url             = module.mq.web_url
      allow_host_mismatch = false
      credentials         = module.mq.user_credentials
      certificates        = null
      endpoints           = module.mq.endpoints
    }
    redis = {
      url      = module.elasticache.redis_endpoint_url.url
      host     = module.elasticache.redis_endpoint_url.host
      port     = module.elasticache.redis_endpoint_url.port
      timeout  = 3000
      ssl_host = ""
      credentials = {
        secret       = ""
        username_key = ""
        password_key = ""
      }
      certificates = {
        secret      = ""
        ca_filename = ""
      }
    }
    mongodb = {
      url                = module.mongodb.url
      host               = module.mongodb.host
      port               = module.mongodb.port
      allow_insecure_tls = true
      credentials = {
        secret       = module.mongodb.user_credentials.secret
        username_key = module.mongodb.user_credentials.username_key
        password_key = module.mongodb.user_credentials.password_key
      }
      certificates = {
        secret      = module.mongodb.user_certificate.secret
        ca_filename = module.mongodb.user_certificate.ca_filename
      }
    }
    shared = {
      service_url       = "https://s3.${var.region}.amazonaws.com"
      kms_key_id        = module.s3_fs.kms_key_id
      name              = module.s3_fs.s3_bucket_name
      access_key_id     = ""
      secret_access_key = ""
      file_storage_type = "S3"
    }
  }
  sensitive = true
}
