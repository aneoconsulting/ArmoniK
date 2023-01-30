# ActiveMQ
module "activemq" {
  source      = "../../../modules/onpremise-storage/activemq"
  namespace   = local.namespace
  working_dir = "${path.root}/../../.."
  activemq = {
    image              = var.activemq.image_name
    tag                = try(coalesce(var.activemq.image_tag), local.default_tags[var.activemq.image_name])
    node_selector      = var.activemq.node_selector
    image_pull_secrets = var.activemq.image_pull_secrets
  }
}

# MongoDB
module "mongodb" {
  source      = "../../../modules/onpremise-storage/mongodb"
  namespace   = local.namespace
  working_dir = "${path.root}/../../.."
  mongodb = {
    image              = var.mongodb.image_name
    tag                = try(coalesce(var.mongodb.image_tag), local.default_tags[var.mongodb.image_name])
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.image_pull_secrets
  }
  persistent_volume = null
}

# Redis
module "redis" {
  count       = var.redis != null ? 1 : 0
  source      = "../../../modules/onpremise-storage/redis"
  namespace   = local.namespace
  working_dir = "${path.root}/../../.."
  redis = {
    image              = var.redis.image_name
    tag                = try(coalesce(var.redis.image_tag), local.default_tags[var.redis.image_name])
    node_selector      = var.redis.node_selector
    image_pull_secrets = var.redis.image_pull_secrets
    max_memory         = var.redis.max_memory
  }
}

# Minio
module "minio" {
  count     = var.minio != null ? 1 : 0
  source    = "../../../modules/onpremise-storage/minio"
  namespace = local.namespace
  minioconfig = {
    host          = var.minio.host
    port          = var.minio.port
    login         = var.minio.login
    password      = var.minio.password
    bucket_name   = var.minio.default_bucket
    image         = var.minio.image_name
    tag           = try(coalesce(var.minio.image_tag), local.default_tags[var.minio.image_name])
    node_selector = var.minio.node_selector
  }
}

# Storage
locals {
  object_storage_adapter = coalesce(
    length(module.redis) > 0 ? "Redis" : null,
    length(module.minio) > 0 ? "S3" : null,
  )
  table_storage_adapter = "ArmoniK.Adapters.MongoDB.TableStorage"
  queue_storage_adapter = "ArmoniK.Adapters.Amqp.QueueStorage"
  storage_endpoint_url = {
    deployed_object_storages = concat(
      ["MongoDB"],
      length(module.redis) > 0 ? ["Redis"] : [],
      length(module.minio) > 0 ? ["S3"] : [],
    )
    activemq = {
      url     = module.activemq.url
      host    = module.activemq.host
      port    = module.activemq.port
      web_url = module.activemq.web_url
      credentials = {
        secret       = module.activemq.user_credentials.secret
        username_key = module.activemq.user_credentials.username_key
        password_key = module.activemq.user_credentials.password_key
      }
      certificates = {
        secret      = module.activemq.user_certificate.secret
        ca_filename = module.activemq.user_certificate.ca_filename
      }
      allow_host_mismatch = true
    }
    redis = length(module.redis) > 0 ? {
      url  = module.redis[0].url
      host = module.redis[0].host
      port = module.redis[0].port
      credentials = {
        secret       = module.redis[0].user_credentials.secret
        username_key = module.redis[0].user_credentials.username_key
        password_key = module.redis[0].user_credentials.password_key
      }
      certificates = {
        secret      = module.redis[0].user_certificate.secret
        ca_filename = module.redis[0].user_certificate.ca_filename
      }
      timeout  = 30000
      ssl_host = "127.0.0.1"
    } : null
    s3 = length(module.minio) > 0 ? {
      url                   = module.minio[0].url
      host                  = module.minio[0].host
      port                  = module.minio[0].port
      login                 = module.minio[0].login
      password              = module.minio[0].password
      bucket_name           = module.minio[0].bucket_name
      must_force_path_style = module.minio[0].must_force_path_style
    } : null
    mongodb = {
      url  = module.mongodb.url
      host = module.mongodb.host
      port = module.mongodb.port
      credentials = {
        secret       = module.mongodb.user_credentials.secret
        username_key = module.mongodb.user_credentials.username_key
        password_key = module.mongodb.user_credentials.password_key
      }
      certificates = {
        secret      = module.mongodb.user_certificate.secret
        ca_filename = module.mongodb.user_certificate.ca_filename
      }
      allow_insecure_tls = true
    }
    shared = var.shared_storage != null ? var.shared_storage : {
      host_path         = abspath("data")
      file_storage_type = "HostPath"
      file_server_ip    = ""
    }
  }
}
