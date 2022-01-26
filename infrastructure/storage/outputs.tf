# MongoDB
output "mongodb_endpoint_url" {
  value = (contains(module.storage.list_storage, "mongodb") ? {
    Status = "READY"
    url    = "mongodb://${local.mongodb_endpoints.ip}:${local.mongodb_endpoints.port}"
    host   = local.mongodb_endpoints.ip
    port   = local.mongodb_endpoints.port
  } : {
    Status = "NOT CREATED"
  })
}

# Redis
output "redis_endpoint_url" {
  value = (contains(module.storage.list_storage, "redis") ? {
    Status = "READY"
    url    = "${local.redis_endpoints.ip}:${local.redis_endpoints.port}"
    host   = local.redis_endpoints.ip
    port   = local.redis_endpoints.port
  } : {
    Status = "NOT CREATED"
  })
}

# ActiveMQ
output "activemq_endpoint_url" {
  value = (contains(module.storage.list_storage, "amqp") ? {
    Status = "READY"
    url    = "${local.activemq_endpoints.ip}:${local.activemq_endpoints.port}"
    host   = local.activemq_endpoints.ip
    port   = local.activemq_endpoints.port
  } : {
    Status = "NOT CREATED"
  })
}

# AWS EBS
output "aws_ebs" {
  value = (contains(module.storage.list_storage, "aws_ebs") ? {
    Status = "READY"
    id     = module.aws_ebs.0.selected.id
  } : {
    Status = "NOT CREATED"
  })
}