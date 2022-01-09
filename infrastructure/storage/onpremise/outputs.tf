# MongoDB
output "mongodb_endpoint_url" {
  value = (contains(module.storage.list_storage, "mongodb") ? {
    Status = "READY"
    url    = "mongodb://${module.mongodb.0.storage.status.0.load_balancer.0.ingress.0.ip}:${module.mongodb.0.storage.spec.0.port.0.port}"
    host   = module.mongodb.0.storage.status.0.load_balancer.0.ingress.0.ip
    port   = module.mongodb.0.storage.spec.0.port.0.port
  } : { Status = "NOT CREATED" })
}

# Redis
output "redis_endpoint_url" {
  value = (contains(module.storage.list_storage, "redis") ? {
    Status = "READY"
    url    = "${module.redis.0.storage.status.0.load_balancer.0.ingress.0.ip}:${module.redis.0.storage.spec.0.port.0.port}"
    host   = module.redis.0.storage.status.0.load_balancer.0.ingress.0.ip
    port   = module.redis.0.storage.spec.0.port.0.port
  } : { Status = "NOT CREATED" })
}

# ActiveMQ
output "activemq_endpoint_url" {
  value = (contains(module.storage.list_storage, "amqp") ? {
    Status = "READY"
    url    = "amqp://${module.activemq.0.storage.status.0.load_balancer.0.ingress.0.ip}:${module.activemq.0.storage.spec.0.port.0.port}"
    host   = module.activemq.0.storage.status.0.load_balancer.0.ingress.0.ip
    port   = module.activemq.0.storage.spec.0.port.0.port
  } : { Status = "NOT CREATED" })
}