# ActiveMQ
module "activemq" {
  source      = "../../../modules/onpremise-storage/activemq"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  activemq    = {
    image         = var.activemq.image
    tag           = var.activemq.tag
    node_selector = var.activemq.node_selector
  }
}

# MongoDB
module "mongodb" {
  source      = "../../../modules/onpremise-storage/mongodb"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  mongodb     = {
    image         = var.mongodb.image
    tag           = var.mongodb.tag
    node_selector = var.mongodb.node_selector
  }
}

# Redis
module "redis" {
  source      = "../../../modules/onpremise-storage/redis"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  redis       = {
    image         = var.redis.image
    tag           = var.redis.tag
    node_selector = var.redis.node_selector
  }
}