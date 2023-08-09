# ActiveMQ
module "activemq" {
  source    = "../generated/infra-modules/storage/onpremise/activemq"
  namespace = var.namespace
  activemq = {
    image              = local.activemq_image
    tag                = local.activemq_tag
    node_selector      = local.activemq_node_selector
    image_pull_secrets = local.activemq_image_pull_secrets
  }
}

# MongoDB
module "mongodb" {
  source    = "../generated/infra-modules/storage/onpremise/mongodb"
  namespace = var.namespace
  mongodb = {
    image              = local.mongodb_image
    tag                = local.mongodb_tag
    node_selector      = local.mongodb_node_selector
    image_pull_secrets = local.mongodb_image_pull_secrets
    replicas_number    = local.mongodb_replicas_number
  }
  persistent_volume = null
}

# Redis
module "redis" {
  count     = var.redis != null ? 1 : 0
  source    = "../generated/infra-modules/storage/onpremise/redis"
  namespace = var.namespace
  redis = {
    image              = local.redis_image
    tag                = local.redis_tag
    node_selector      = local.redis_node_selector
    image_pull_secrets = local.redis_image_pull_secrets
    max_memory         = local.redis_max_memory
  }
}

# minio
module "minio" {
  count     = var.minio != null ? 1 : 0
  source    = "../generated/infra-modules/storage/onpremise/minio"
  namespace = var.namespace
  minio = {
    image              = local.minio_image
    tag                = local.minio_tag
    image_pull_secrets = local.minio_image_pull_secrets
    host               = local.minio_host
    bucket_name        = local.minio_bucket_name
    node_selector      = local.minio_node_selector
  }
}


# minio for file storage
module "minio_s3_fs" {
  count     = var.minio_s3_fs != null ? 1 : 0
  source    = "../generated/infra-modules/storage/onpremise//minio"
  namespace = var.namespace
  minio = {
    image              = local.minio_s3_fs_image
    tag                = local.minio_s3_fs_tag
    image_pull_secrets = local.minio_s3_fs_image_pull_secrets
    host               = local.minio_s3_fs_host
    bucket_name        = local.minio_s3_fs_bucket_name
    node_selector      = local.minio_s3_fs_node_selector
  }
}
