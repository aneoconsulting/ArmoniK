# Node IP of Redis pod
data "external" "redis_node_ip" {
  depends_on  = [module.redis]
  program     = ["bash", "get_node_ip.sh", "redis", var.namespace]
  working_dir = "../utils/scripts"
}

# Node IP of MongoDB pod
data "external" "mongodb_node_ip" {
  depends_on  = [module.mongodb]
  program     = ["bash", "get_node_ip.sh", "mongodb", var.namespace]
  working_dir = "../utils/scripts"
}

# Node IP of ActiveMQ pod
data "external" "activemq_node_ip" {
  depends_on  = [module.activemq]
  program     = ["bash", "get_node_ip.sh", "activemq", var.namespace]
  working_dir = "../utils/scripts"
}

# Node names
locals {
  # MongoDB
  mongodb_endpoints = (contains(module.storage.list_storage, "mongodb") ? {
    ip   = module.mongodb.0.service.spec.0.cluster_ip
    port = module.mongodb.0.service.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })

  # Redis
  redis_endpoints = (contains(module.storage.list_storage, "redis") ? {
    ip   = module.redis.0.service.spec.0.cluster_ip
    port = module.redis.0.service.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })

  # ActiveMQ
  activemq_endpoints = (contains(module.storage.list_storage, "amqp") ? {
    ip   = module.activemq.0.service.spec.0.cluster_ip
    port = module.activemq.0.service.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })
}

