locals {
  # ActiveMQ
  activemq_image              = try(var.activemq.image, "symptoma/activemq")
  activemq_tag                = try(var.activemq.tag, "5.16.3")
  activemq_node_selector      = try(var.activemq.node_selector, {})
  activemq_image_pull_secrets = try(var.activemq.image_pull_secrets, "")

  # MongoDB
  mongodb_image              = try(var.mongodb.image, "mongo")
  mongodb_tag                = try(var.mongodb.tag, "4.4.11")
  mongodb_node_selector      = try(var.mongodb.node_selector, {})
  mongodb_image_pull_secrets = try(var.mongodb.image_pull_secrets, {})

  # Redis
  redis_image              = try(var.redis.image, "redis")
  redis_tag                = try(var.redis.tag, "bullseye")
  redis_node_selector      = try(var.redis.node_selector, {})
  redis_image_pull_secrets = try(var.redis.image_pull_secrets, {})
  redis_max_memory         = try(var.redis.max_memory, "12000mb")

  # S3 payload
  minio_image              = try(var.minio.image, "quay.io/minio/minio")
  minio_tag                = try(var.minio.tag, "latest")
  minio_node_selector      = try(var.minio.node_selector, {})

  # Shared storage
  shared_storage_host_path         = try(var.shared_storage.host_path, "/data")
  shared_storage_file_storage_type = try(var.shared_storage.file_storage_type, "HostPath")
  shared_storage_file_server_ip    = try(var.shared_storage.file_server_ip, "")
}