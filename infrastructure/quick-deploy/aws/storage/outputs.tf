# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLs"
  value = {
    activemq = {
      url     = module.mq.activemq_endpoint_url.url
      web_url = module.mq.web_url
    }
    redis = {
      url = module.elasticache.redis_endpoint_url.url
    }
    mongodb = {
      url = module.mongodb.url
    }
    shared = {
      service_url       = "https://s3.${var.region}.amazonaws.com"
      kms_key_id        = module.s3_fs.kms_key_id
      name              = module.s3_fs.s3_bucket_name
      file_storage_type = "S3"
    }
  }
}
