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


  # SeaweedFS file storage
  shared_storage_seaweedfs_s3_fs = var.seaweedfs_s3_fs != null ? {
    file_storage_type     = "s3"
    service_url           = module.seaweedfs_s3_fs[0].url
    console_url           = module.seaweedfs_s3_fs[0].console_url
    access_key_id         = module.seaweedfs_s3_fs[0].login
    secret_access_key     = module.seaweedfs_s3_fs[0].password
    name                  = module.seaweedfs_s3_fs[0].bucket_name
    must_force_path_style = module.seaweedfs_s3_fs[0].must_force_path_style
  } : {}
  shared_storage_localhost_default = {
    host_path         = abspath(var.shared_storage.host_path)
    file_storage_type = var.shared_storage.file_storage_type
    file_server_ip    = var.shared_storage.file_server_ip
  }
  shared_storage = var.seaweedfs_s3_fs != null ? local.shared_storage_seaweedfs_s3_fs : local.shared_storage_localhost_default
}
