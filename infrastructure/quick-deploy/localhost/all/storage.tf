# ActiveMQ
module "activemq" {
  source      = "../../../modules/onpremise-storage/activemq"
  namespace   = local.namespace
  working_dir = "${path.root}/../../.."
  activemq = {
    image              = var.activemq.image_name
    tag                = var.activemq.image_tag
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
    tag                = var.mongodb.image_tag
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.image_pull_secrets
  }
  persistent_volume = null
}

# Redis
module "redis" {
  source      = "../../../modules/onpremise-storage/redis"
  namespace   = local.namespace
  working_dir = "${path.root}/../../.."
  redis = {
    image              = var.redis.image_name
    tag                = var.redis.image_tag
    node_selector      = var.redis.node_selector
    image_pull_secrets = var.redis.image_pull_secrets
    max_memory         = var.redis.max_memory
  }
}

# Shared storage
resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage-endpoints"
    namespace = var.namespace
  }
  data = {
    host_path         = abspath("data")
    file_storage_type = "HostPath"
    file_server_ip    = ""
  }
}

# Storage
locals {
  storage_endpoint_url = {
    activemq = {
      url                 = module.activemq.url
      host                = module.activemq.host
      port                = module.activemq.port
      web_url             = module.activemq.web_url
      credentials         = module.activemq.user_credentials
      certificates        = module.activemq.user_certificate
      endpoints           = module.activemq.endpoints
      allow_host_mismatch = true
    }
    redis = {
      url          = module.redis.url
      host         = module.redis.host
      port         = module.redis.port
      credentials  = module.redis.user_credentials
      certificates = module.redis.user_certificate
      endpoints    = module.redis.endpoints
      timeout      = 30000
      ssl_host     = "127.0.0.1"
    }
    mongodb = {
      url                = module.mongodb.url
      host               = module.mongodb.host
      port               = module.mongodb.port
      credentials        = module.mongodb.user_credentials
      certificates       = module.mongodb.user_certificate
      endpoints          = module.mongodb.endpoints
      allow_insecure_tls = true
    }
    shared = var.shared_storage != null ? var.shared_storage : {
      host_path         = abspath("data")
      file_storage_type = "HostPath"
      file_server_ip    = ""
    }
  }
}
