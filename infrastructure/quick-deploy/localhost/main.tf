# ActiveMQ
module "activemq" {
  count       = (var.deploy.storage ? 1 : 0)
  source      = "../../storage/onpremise/modules/activemq"
  namespace   = var.kubernetes_namespaces.storage
  working_dir = "../.."
  activemq    = {
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
  count       = (var.deploy.storage ? 1 : 0)
  source      = "../../storage/onpremise/modules/mongodb"
  namespace   = var.kubernetes_namespaces.storage
  working_dir = "../.."
  mongodb     = {
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
  count       = (var.deploy.storage ? 1 : 0)
  source      = "../../storage/onpremise/modules/redis"
  namespace   = var.kubernetes_namespaces.storage
  working_dir = "../.."
  redis       = {
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
  count       = (var.deploy.monitoring ? 1 : 0)
  source      = "../../armonik/modules/monitoring/seq"
  namespace   = var.kubernetes_namespaces.monitoring
  working_dir = "../.."
}

# ArmoniK
module "armonik" {
  count                = (var.deploy.armonik ? 1 : 0)
  source               = "../../armonik/modules/armonik-components"
  namespace            = var.kubernetes_namespaces.armonik
  working_dir          = "../.."
  logging_level        = var.logging_level
  fluent_bit           = {
    image = var.fluent_bit.image
    tag   = var.fluent_bit.tag
  }
  seq_endpoints        = (var.deploy.monitoring ? {
    url  = module.seq.0.url
    host = module.seq.0.host
    port = module.seq.0.port
  } : {
    url  = var.seq_endpoints.url
    host = var.seq_endpoints.host
    port = var.seq_endpoints.port
  })
  storage_adapters     = {
    object         = "Redis.ObjectStorage"
    table          = "MongoDB.TableStorage"
    queue          = "Amqp.QueueStorage"
    lease_provider = "MongoDB.LeaseProvider"
  }
  storage_endpoint_url = {
    activemq = {
      host   = (var.deploy.storage ? module.activemq.0.host : var.storage_endpoint_url.activemq.host)
      port   = (var.deploy.storage ? module.activemq.0.port : var.storage_endpoint_url.activemq.port)
      secret = var.kubernetes_secrets.activemq_client
    }
    external = {
      url    = (var.deploy.storage ? module.redis.0.url : var.storage_endpoint_url.redis.url)
      secret = var.kubernetes_secrets.external_client
    }
    mongodb  = {
      host   = (var.deploy.storage ? module.mongodb.0.host : var.storage_endpoint_url.mongodb.host)
      port   = (var.deploy.storage ? module.mongodb.0.port : var.storage_endpoint_url.mongodb.port)
      secret = var.kubernetes_secrets.mongodb_client
    }
    redis    = {
      url    = (var.deploy.storage ? module.redis.0.url : var.storage_endpoint_url.redis.url)
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