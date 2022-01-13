# MongoDB
output "mongodb_endpoint_url" {
  value = (contains(module.storage.list_storage, "mongodb") ? (local.mongodb_node_ip == "" ? {
    Status = "READY"
    url    = "mongodb://${module.mongodb.0.service.spec.cluster_ip}:${module.mongodb.0.service.spec.0.port.0.port}"
    host   = module.mongodb.0.service.spec.cluster_ip
    port   = module.mongodb.0.service.spec.0.port.0.port
  } : {
    Status = "READY"
    url    = "mongodb://${local.mongodb_node_ip}:${module.mongodb.0.service.spec.0.port.0.node_port}"
    host   = local.mongodb_node_ip
    port   = module.mongodb.0.service.spec.0.port.0.node_port
  }) : { Status = "NOT CREATED" })
}

# Redis
output "redis_endpoint_url" {
  value = (contains(module.storage.list_storage, "redis") ? (local.redis_node_ip == "" ? {
    Status = "READY"
    url    = "${module.redis.0.service.spec.cluster_ip}:${module.redis.0.service.spec.0.port.0.port}"
    host   = module.redis.0.service.spec.cluster_ip
    port   = module.redis.0.service.spec.0.port.0.port
  } : {
    Status = "READY"
    url    = "${local.redis_node_ip}:${module.redis.0.service.spec.0.port.0.node_port}"
    host   = local.redis_node_ip
    port   = module.redis.0.service.spec.0.port.0.node_port
  }) : { Status = "NOT CREATED" })
}

# ActiveMQ
output "activemq_endpoint_url" {
  value = (contains(module.storage.list_storage, "amqp") ? (local.activemq_node_ip== "" ? {
    Status = "READY"
    url    = "amqp://${module.activemq.0.service.spec.cluster_ip}:${module.activemq.0.service.spec.0.port.0.port}"
    host   = module.activemq.0.service.spec.cluster_ip
    port   = module.activemq.0.service.spec.0.port.0.port
  } : {
    Status = "READY"
    url    = "amqp://${local.activemq_node_ip}:${module.activemq.0.service.spec.0.port.0.node_port}"
    host   = local.activemq_node_ip
    port   = module.activemq.0.service.spec.0.port.0.node_port
  }) : { Status = "NOT CREATED" })
}