locals {
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