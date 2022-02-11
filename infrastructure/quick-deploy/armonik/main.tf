# MongoDB
module "mongodb" {
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

# Seq
module "seq" {
  source      = "../../armonik/modules/monitoring/seq"
  namespace   = var.kubernetes_namespaces.monitoring
  working_dir = "../.."
}

# ArmoniK
module "armonik" {
  source               = "../../armonik/modules/armonik-components"
  namespace            = var.kubernetes_namespaces.armonik
  working_dir          = "../.."
  logging_level        = var.logging_level
  fluent_bit           = {
    name  = var.fluent_bit.name
    image = var.fluent_bit.image
    tag   = var.fluent_bit.tag
  }
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
      host   = var.storage_endpoint_url.activemq.host
      port   = var.storage_endpoint_url.activemq.port
      secret = var.kubernetes_secrets.activemq_client
    }
    external = {
      url    = var.storage_endpoint_url.redis.url
      secret = var.kubernetes_secrets.external_client
    }
    mongodb  = {
      host   = module.mongodb.host
      port   = module.mongodb.port
      secret = var.kubernetes_secrets.mongodb_client
    }
    redis    = {
      url    = var.storage_endpoint_url.redis.url
      secret = var.kubernetes_secrets.redis_client
    }
    shared   = {
      host   = ""
      secret = ""
      id     = var.storage_endpoint_url.shared.name
      path   = var.storage_endpoint_url.shared.host_path
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
    module.mongodb,
    module.seq,
  ]
}