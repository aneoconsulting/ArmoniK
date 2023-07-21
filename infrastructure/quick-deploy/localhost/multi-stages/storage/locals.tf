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
  mongodb_replicas_number    = try(var.mongodb.replicas_number, 1)

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

  # Minio for file storage
  minio_s3_fs_image              = try(var.minio_s3_fs.image, "minio/minio")
  minio_s3_fs_tag                = try(var.minio_s3_fs.tag, "RELEASE.2023-01-25T00-19-54Z")
  minio_s3_fs_image_pull_secrets = try(var.minio_s3_fs.image_pull_secrets, "")
  minio_s3_fs_host               = try(var.minio_s3_fs.host, "minio_s3_fs")
  minio_s3_fs_bucket_name        = try(var.minio_s3_fs.default_bucket, "minioBucket")
  minio_s3_fs_node_selector      = try(var.minio_s3_fs.node_selector, {})
  shared_storage_minio_s3_fs = var.minio_s3_fs != null ? {
    file_storage_type     = "s3"
    host                  = module.minio_s3_fs[0].host
    service_url           = module.minio_s3_fs[0].url
    console_url           = module.minio_s3_fs[0].console_url
    access_key_id         = module.minio_s3_fs[0].login
    secret_access_key     = module.minio_s3_fs[0].password
    name                  = module.minio_s3_fs[0].bucket_name
    must_force_path_style = module.minio_s3_fs[0].must_force_path_style
  } : {}
  shared_storage_localhost_default = {
    host_path         = try(var.shared_storage.host_path, "/data")
    file_storage_type = try(var.shared_storage.file_storage_type, "HostPath")
    file_server_ip    = try(var.shared_storage.file_server_ip, "")
  }
  shared_storage = var.minio_s3_fs != null ? local.shared_storage_minio_s3_fs : local.shared_storage_localhost_default



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