# ActiveMQ
module "activemq" {
  source      = "../../../modules/onpremise-storage/activemq"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  activemq = {
    image              = local.activemq_image
    tag                = local.activemq_tag
    node_selector      = local.activemq_node_selector
    image_pull_secrets = local.activemq_image_pull_secrets
  }
}

# MongoDB
module "mongodb" {
  source      = "../../../modules/onpremise-storage/mongodb"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  mongodb = {
    image              = local.mongodb_image
    tag                = local.mongodb_tag
    node_selector      = local.mongodb_node_selector
    image_pull_secrets = local.mongodb_image_pull_secrets
  }
  persistent_volume = null
}

# Redis
module "redis" {
  count       = (contains([for each in var.object_storages_to_be_deployed : lower(each)], lower("redis"))) ? 1 : 0
  source      = "../../../modules/onpremise-storage/redis"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
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
  count     = (contains([for each in var.object_storages_to_be_deployed : lower(each)], lower("s3"))) ? 1 : 0
  source    = "../../../modules/onpremise-storage/minio"
  namespace = var.namespace
  minio     = var.minio
}
