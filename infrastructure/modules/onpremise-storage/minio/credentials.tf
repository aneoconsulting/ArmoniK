resource "random_string" "minio_application_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "minio_application_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "s3_endpoints" {
  metadata {
    name      = "s3-object-storage-endpoints"
    namespace = var.namespace
  }
  data = {
    url                   = "http://${var.minio.host}:${local.port}"
    host                  = var.minio.host
    port                  = local.port
    login                 = random_string.minio_application_user.result
    password              = random_password.minio_application_password.result
    bucket_name           = var.minio.bucket_name
    must_force_path_style = true
  }
}