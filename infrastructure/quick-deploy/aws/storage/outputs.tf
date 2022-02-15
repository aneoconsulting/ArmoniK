# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLS"
  value       = {
    activemq = {
      url                 = module.mq.activemq_endpoint_url.url
      host                = module.mq.activemq_endpoint_url.host
      port                = module.mq.activemq_endpoint_url.port
      web_url             = module.mq.web_url
      allow_host_mismatch = false
      credentials         = {
        file         = module.mq.creds.file
        kms_key_id   = module.mq.creds.kms_key_id
      }
      certificates        = {
        secret      = ""
        ca_filename = ""
      }
    }
    redis    = {
      url          = module.elasticache.redis_endpoint_url.url
      host         = module.elasticache.redis_endpoint_url.host
      port         = module.elasticache.redis_endpoint_url.port
      timeout      = 3000
      ssl_host     = ""
      certificates = {
        secret      = ""
        ca_filename = ""
      }
      credentials  = {
        secret       = ""
        username_key = ""
        password_key = ""
      }
    }
    shared   = {
      region     = var.region
      kms_key_id = module.s3_fs.kms_key_id
      name       = module.s3_fs.s3_bucket_name
    }
  }
}
