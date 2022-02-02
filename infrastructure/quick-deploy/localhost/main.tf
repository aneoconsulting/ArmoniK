# ActiveMQ
module "activemq" {
  source    = "../../storage/onpremise/modules/activemq"
  namespace = var.kubernetes_namespaces.storage
  activemq  = {
    replicas      = var.activemq.replicas
    port          = var.activemq.port
    image         = var.activemq.image
    tag           = var.activemq.tag
    secret        = var.kubernetes_secrets.activemq_server
    node_selector = var.activemq.node_selector
  }
}

# MongoDB
module "mongodb" {
  source    = "../../storage/onpremise/modules/mongodb"
  namespace = var.kubernetes_namespaces.storage
  mongodb   = {
    replicas      = var.mongodb.replicas
    port          = var.mongodb.port
    image         = var.mongodb.image
    tag           = var.mongodb.tag
    secret        = var.kubernetes_secrets.mongodb_server
    node_selector = var.mongodb.node_selector
  }
}

# Redis
module "redis" {
  source    = "../../storage/onpremise/modules/redis"
  namespace = var.kubernetes_namespaces.storage
  redis     = {
    replicas      = var.redis.replicas
    port          = var.redis.port
    image         = var.redis.image
    tag           = var.redis.tag
    secret        = var.kubernetes_secrets.redis_server
    node_selector = var.redis.node_selector
  }
}

# Seq
module "seq" {
  source    = "../../monitoring/modules/seq"
  namespace = var.kubernetes_namespaces.monitoring
}

# ArmoniK
module "armonik" {
  source               = "../../armonik/modules/armonik-components"
  namespace            = var.kubernetes_namespaces.armonik
  working_dir          = "../.."
  logging_level        = var.logging_level
  seq_endpoints        = {
    url  = module.seq.url
    host = module.seq.host
    port = module.seq.port
  }
  storage_adapters     = {
    object         = "Redis.ObjectStorage"
    table          = "MongoDB.TableStorage"
    queue          = "Amqp.QueueStorage"
    lease_provider = "MongoDB.LeaseProvider"
  }
  storage_endpoint_url = {
    activemq = {
      host   = module.activemq.host
      port   = module.activemq.port
      secret = var.kubernetes_secrets.activemq_client
    }
    external = {
      url    = module.redis.url
      secret = var.kubernetes_secrets.external_client
    }
    mongodb  = {
      host   = module.mongodb.host
      port   = module.mongodb.port
      secret = var.kubernetes_secrets.mongodb_client
    }
    redis    = {
      url    = module.redis.url
      secret = var.kubernetes_secrets.redis_client
    }
    shared   = {
      host   = ""
      secret = ""
      id     = ""
      path   = var.host_path
    }
  }
  storage              = {
    list      = ["amqp", "mongodb", "redis"]
    data_type = {
      object         = "redis"
      table          = "mongodb"
      queue          = "amqp"
      lease_provider = "mongodb"
      shared         = "hostpath"
      external       = "redis"
    }
  }
  control_plane        = var.control_plane
  compute_plane        = var.compute_plane
  depends_on           = [
    module.activemq,
    module.mongodb,
    module.redis,
    module.seq,
  ]
}