# MongoDB
output "mongodb_endpoint_url" {
  value = (contains(module.storage.list_of_storage, "mongodb") ? "mongodb://${module.mongodb.0.storage.spec.0.cluster_ip}:${module.mongodb.0.storage.spec.0.port.0.port}" : "NOT CREATED")
}

# Redis
output "redis_endpoint_url" {
  value = (contains(module.storage.list_of_storage, "redis") ? "${module.redis.0.storage.spec.0.cluster_ip}:${module.redis.0.storage.spec.0.port.0.port}" : "NOT CREATED")
}

# ActiveMQ
output "activemq_endpoint_url" {
  value = (contains(module.storage.list_of_storage, "amqp") ? "amqp://${module.activemq.0.storage.spec.0.cluster_ip}:${module.activemq.0.storage.spec.0.port.0.port}" : "NOT CREATED")
}