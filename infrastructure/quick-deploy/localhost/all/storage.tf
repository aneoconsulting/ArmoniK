# ActiveMQ
module "activemq" {
  source      = "../../../modules/onpremise-storage/activemq"
  namespace   = var.namespace
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
  namespace   = var.namespace
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
  source      = "../../../modules/onpremise-storage/redis"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  redis = {
    image              = var.redis.image_name
    tag                = try(coalesce(var.redis.image_tag), local.default_tags[var.redis.image_name])
    node_selector      = var.redis.node_selector
    image_pull_secrets = var.redis.image_pull_secrets
    max_memory         = var.redis.max_memory
  }
}

# Storage
locals {
  storage_endpoint_url = {
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
    redis = {
      url  = module.redis.url
      host = module.redis.host
      port = module.redis.port
      credentials = {
        secret       = module.redis.user_credentials.secret
        username_key = module.redis.user_credentials.username_key
        password_key = module.redis.user_credentials.password_key
      }
      certificates = {
        secret      = module.redis.user_certificate.secret
        ca_filename = module.redis.user_certificate.ca_filename
      }
      timeout  = 30000
      ssl_host = "127.0.0.1"
    }
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
