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
  mongodb_replicas_number    = try(var.mongodb.replicas_number, 2)

  # Redis
  redis_image              = try(var.redis.image, "redis")
  redis_tag                = try(var.redis.tag, "bullseye")
  redis_node_selector      = try(var.redis.node_selector, {})
  redis_image_pull_secrets = try(var.redis.image_pull_secrets, "")
  redis_max_memory         = try(var.redis.max_memory, "12000mb")

  # Minio
  minio_image              = try(var.minio.image, "minio/minio")
  minio_tag                = try(var.minio.tag, "RELEASE.2023-01-25T00-19-54Z")
  minio_image_pull_secrets = try(var.minio.image_pull_secrets, "")
  minio_host               = try(var.minio.host, "minio")
  minio_bucket_name        = try(var.minio.default_bucket, "minioBucket")
  minio_node_selector      = try(var.minio.node_selector, {})

  # Shared storage
  shared_storage_host_path         = try(var.shared_storage.host_path, "/data")
  shared_storage_file_storage_type = try(var.shared_storage.file_storage_type, "HostPath")
  shared_storage_file_server_ip    = try(var.shared_storage.file_server_ip, "")

  # Deployed storage
  deployed_object_storages = concat(
    length(module.redis) > 0 ? ["Redis"] : [],
    length(module.minio) > 0 ? ["S3"] : [],
  )
  deployed_table_storages = ["MongoDB"]
  deployed_queue_storages = ["Amqp"]

  # Storage adapters
  object_storage_adapter = try(coalesce(
    length(module.redis) > 0 ? "Redis" : null,
    length(module.minio) > 0 ? "S3" : null,
  ), "")
  table_storage_adapter = "MongoDB"
  queue_storage_adapter = "Amqp"
}