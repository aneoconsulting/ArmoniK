# ActiveMQ
module "activemq" {
  source    = "../generated/infra-modules/storage/onpremise/activemq"
  namespace = var.namespace
  activemq = {
    image              = var.activemq.image_name
    tag                = try(var.image_tags[var.activemq.image_name], var.activemq)
    node_selector      = var.activemq.node_selector
    image_pull_secrets = var.activemq.image_pull_secrets
  }
}

# MongoDB
module "mongodb" {
  source    = "../generated/infra-modules/storage/onpremise/mongodb"
  namespace = var.namespace
  mongodb = {
    image              = var.mongodb.image_name
    tag                = try(var.image_tags[var.mongodb.image_name], var.mongodb.image_tag)
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.image_pull_secrets
    replicas_number    = var.mongodb.replicas_number
  }
  persistent_volume = null
}

# Redis
module "redis" {
  count     = var.redis != null ? 1 : 0
  source    = "../generated/infra-modules/storage/onpremise/redis"
  namespace = var.namespace
  redis = {
    image              = var.redis.image_name
    tag                = try(var.image_tags[var.redis.image_name], var.redis)
    node_selector      = var.redis.node_selector
    image_pull_secrets = var.redis.image_pull_secrets
    max_memory         = var.redis.max_memory
    service_type       = var.redis.service_type
  }
}

# minio
module "minio" {
  count     = var.minio != null ? 1 : 0
  source    = "../generated/infra-modules/storage/onpremise/minio"
  namespace = var.namespace
  minio = {
    image              = var.minio.image_name
    tag                = try(var.image_tags[var.minio.image_name], var.minio)
    node_selector      = var.minio.node_selector
    image_pull_secrets = var.minio.image_pull_secrets
    host               = var.minio.host
    bucket_name        = var.minio.default_bucket
  }
}


# minio for file storage
module "minio_s3_fs" {
  count     = var.minio_s3_fs != null ? 1 : 0
  source    = "../generated/infra-modules/storage/onpremise//minio"
  namespace = var.namespace
  minio = {
    image              = var.minio_s3_fs.image_name
    tag                = try(var.image_tags[var.minio_s3_fs.image_name], var.minio_s3_fs.image_tag)
    node_selector      = var.minio_s3_fs.node_selector
    image_pull_secrets = var.minio_s3_fs.image_pull_secrets
    host               = var.minio_s3_fs.host
    bucket_name        = var.minio_s3_fs.default_bucket
  }
}
