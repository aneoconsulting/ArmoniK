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
      timeout      = 3000
      ssl_host     = ""
      credentials  = null
      certificates = null
      endpoints    = module.elasticache.endpoints
    }
    mongodb = {
      credentials        = module.mongodb.user_credentials
      certificates       = module.mongodb.user_certificate
      endpoints          = module.mongodb.endpoints
      allow_insecure_tls = true
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
