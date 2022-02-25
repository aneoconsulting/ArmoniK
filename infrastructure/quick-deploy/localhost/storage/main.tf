# ActiveMQ
module "activemq" {
  source      = "../../../modules/onpremise-storage/activemq"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  activemq    = {
    image         = local.activemq_image
    tag           = local.activemq_tag
    node_selector = local.activemq_node_selector
  }
}

# MongoDB
module "mongodb" {
  source      = "../../../modules/onpremise-storage/mongodb"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  mongodb     = {
    image         = local.mongodb_image
    tag           = local.mongodb_tag
    node_selector = local.mongodb_node_selector
  }
}

# Redis
module "redis" {
  source      = "../../../modules/onpremise-storage/redis"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  redis       = {
    image         = local.redis_image
    tag           = local.redis_tag
    node_selector = local.redis_node_selector
  }
}