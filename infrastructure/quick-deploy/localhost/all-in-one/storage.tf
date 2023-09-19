# ActiveMQ
module "activemq" {
  source    = "./generated/infra-modules/storage/onpremise/activemq"
  namespace = local.namespace
  activemq = {
    image                 = var.activemq.image_name
    tag                   = try(coalesce(var.activemq.image_tag), local.default_tags[var.activemq.image_name])
    node_selector         = var.activemq.node_selector
    image_pull_secrets    = var.activemq.image_pull_secrets
    adapter_class_name    = var.activemq.adapter_class_name
    adapter_absolute_path = var.activemq.adapter_absolute_path
  }
}

# MongoDB
module "mongodb" {
  source    = "./generated/infra-modules/storage/onpremise/mongodb"
  namespace = local.namespace
  mongodb = {
    image              = var.mongodb.image_name
    tag                = try(coalesce(var.mongodb.image_tag), local.default_tags[var.mongodb.image_name])
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.image_pull_secrets
    replicas_number    = var.mongodb.replicas_number
  }
  persistent_volume = null
}

# Redis
module "redis" {
  count     = var.redis != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/redis"
  namespace = local.namespace
  redis = {
    image              = var.redis.image_name
    tag                = try(coalesce(var.redis.image_tag), local.default_tags[var.redis.image_name])
    node_selector      = var.redis.node_selector
    image_pull_secrets = var.redis.image_pull_secrets
    max_memory         = var.redis.max_memory
  }
}

# minio
module "minio" {
  count     = var.minio != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/minio"
  namespace = local.namespace
  minio = {
    image              = var.minio.image_name
    tag                = try(coalesce(var.minio.image_tag), local.default_tags[var.minio.image_name])
    node_selector      = var.minio.node_selector
    image_pull_secrets = var.minio.image_pull_secrets
    host               = var.minio.host
    bucket_name        = var.minio.default_bucket
  }
}

# minio for file storage
module "minio_s3_fs" {
  count     = var.minio_s3_fs != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/minio"
  namespace = local.namespace
  minio = {
    image              = local.minio_s3_fs_image
    tag                = try(coalesce(var.minio.image_tag), local.default_tags[var.minio_s3_fs.image_name])
    image_pull_secrets = local.minio_s3_fs_image_pull_secrets
    host               = local.minio_s3_fs_host
    bucket_name        = local.minio_s3_fs_bucket_name
    node_selector      = local.minio_s3_fs_node_selector
  }
}

# Shared storage
resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage"
    namespace = local.namespace
  }
  data = local.shared_storage
}

resource "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = "deployed-object-storage"
    namespace = local.namespace
  }
  data = {
    list    = join(",", local.storage_endpoint_url.deployed_object_storages)
    adapter = local.storage_endpoint_url.object_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_table_storage" {
  metadata {
    name      = "deployed-table-storage"
    namespace = local.namespace
  }
  data = {
    list    = join(",", local.storage_endpoint_url.deployed_table_storages)
    adapter = local.storage_endpoint_url.table_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_queue_storage" {
  metadata {
    name      = "deployed-queue-storage"
    namespace = local.namespace
  }
  data = {
    list                  = join(",", local.storage_endpoint_url.deployed_queue_storages)
    adapter               = local.storage_endpoint_url.queue_storage_adapter
    adapter_class_name    = module.activemq.adapter_class_name
    adapter_absolute_path = module.activemq.adapter_absolute_path
  }
}

# Storage
locals {
  storage_endpoint_url = {
    object_storage_adapter = try(coalesce(
      length(module.redis) > 0 ? "Redis" : null,
      length(module.minio) > 0 ? "S3" : null,
    ), "")
    table_storage_adapter = "MongoDB"
    queue_storage_adapter = "Amqp"
    deployed_object_storages = concat(
      length(module.redis) > 0 ? ["Redis"] : [],
      length(module.minio) > 0 ? ["S3"] : [],
    )
    deployed_table_storages = ["MongoDB"]
    deployed_queue_storages = ["Amqp"]
    activemq = {
      url                   = module.activemq.url
      host                  = module.activemq.host
      port                  = module.activemq.port
      web_url               = module.activemq.web_url
      credentials           = module.activemq.user_credentials
      certificates          = module.activemq.user_certificate
      endpoints             = module.activemq.endpoints
      adapter_class_name    = module.activemq.adapter_class_name
      adapter_absolute_path = module.activemq.adapter_absolute_path
      engine_type           = module.activemq.engine_type
      allow_host_mismatch   = true
    }
    redis = length(module.redis) > 0 ? {
      url          = module.redis[0].url
      host         = module.redis[0].host
      port         = module.redis[0].port
      credentials  = module.redis[0].user_credentials
      certificates = module.redis[0].user_certificate
      endpoints    = module.redis[0].endpoints
      timeout      = 30000
      ssl_host     = "127.0.0.1"
    } : null
    mongodb = {
      url                = module.mongodb.url
      host               = module.mongodb.host
      port               = module.mongodb.port
      credentials        = module.mongodb.user_credentials
      certificates       = module.mongodb.user_certificate
      endpoints          = module.mongodb.endpoints
      number_of_replicas = var.mongodb.replicas_number
      allow_insecure_tls = true
    }
    shared = var.shared_storage != null ? var.shared_storage : {
      host_path         = abspath("data")
      file_storage_type = "HostPath"
      file_server_ip    = ""
    }
    s3 = length(module.minio) > 0 ? {
      url         = try(module.minio[0].url, "")
      bucket_name = try(module.minio[0].bucket_name, "")
    } : null
  }
}
