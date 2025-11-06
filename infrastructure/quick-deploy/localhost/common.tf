resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.namespace
  }
}

locals {
  prefix    = try(coalesce(var.prefix), "armonik-${random_string.prefix.result}")
  namespace = kubernetes_namespace.armonik.metadata[0].name


  # Minio file storage
  minio_s3_fs_image              = try(var.minio_s3_fs.image, "minio/minio")
  minio_s3_fs_image_pull_secrets = try(var.minio_s3_fs.image_pull_secrets, "")
  minio_s3_fs_host               = try(var.minio_s3_fs.host, "minio_s3_fs")
  minio_s3_fs_bucket_name        = try(var.minio_s3_fs.default_bucket, "minio-bucket")
  minio_s3_fs_node_selector      = try(var.minio_s3_fs.node_selector, {})
  shared_storage_minio_s3_fs = var.minio_s3_fs != null ? {
    file_storage_type     = "s3"
    service_url           = module.minio_s3_fs[0].url
    console_url           = module.minio_s3_fs[0].console_url
    access_key_id         = module.minio_s3_fs[0].login
    secret_access_key     = module.minio_s3_fs[0].password
    name                  = module.minio_s3_fs[0].bucket_name
    must_force_path_style = module.minio_s3_fs[0].must_force_path_style
  } : {}
  shared_storage_localhost_default = {
    host_path         = abspath(var.shared_storage.host_path)
    file_storage_type = var.shared_storage.file_storage_type
    file_server_ip    = var.shared_storage.file_server_ip
  }
  shared_storage = var.minio_s3_fs != null ? local.shared_storage_minio_s3_fs : local.shared_storage_localhost_default
}
