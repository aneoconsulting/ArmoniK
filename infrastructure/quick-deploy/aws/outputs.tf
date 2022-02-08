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
  }
}

# S3 bucket as shared storage
output "s3_bucket_fs" {
  description = "S3 bucket as shared storage"
  value       = module.s3_bucket_fs.s3_bucket_name
}

# VPC
output "vpc" {
  description = "VPC infos"
  value       = {
    id          = module.vpc.id
    cidr_blocks = concat([module.vpc.cidr_block], module.vpc.pod_cidr_block_private)
    subnet_ids  = module.vpc.private_subnet_ids
  }
}

# EKS
output "eks_name" {
  description = "EKS name"
  value       = module.eks.eks_name
}