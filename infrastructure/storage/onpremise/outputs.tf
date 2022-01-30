# MongoDB
output "mongodb_endpoint_url" {
  value = (contains(module.storage.list_storage, "mongodb") ? {
    Status = "READY"
    url    = module.mongodb.0.url
    host   = module.mongodb.0.host
    port   = module.mongodb.0.port
  } : {
    Status = "NOT CREATED"
  })
}

# Redis
output "redis_endpoint_url" {
  value = (contains(module.storage.list_storage, "redis") ? {
    Status = "READY"
    url    = module.redis.0.url
    host   = module.redis.0.host
    port   = module.redis.0.port
  } : {
    Status = "NOT CREATED"
  })
}

# ActiveMQ
output "activemq_endpoint_url" {
  value = (contains(module.storage.list_storage, "amqp") ? {
    Status = "READY"
    url    = module.activemq.0.url
    host   = module.activemq.0.host
    port   = module.activemq.0.port
  } : {
    Status = "NOT CREATED"
  })
}