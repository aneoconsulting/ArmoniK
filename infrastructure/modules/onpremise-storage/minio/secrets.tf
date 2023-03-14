resource "kubernetes_secret" "minio" {
  metadata {
    name      = "s3"
    namespace = var.namespace
  }
  data = {
    username              = random_string.minio_application_user.result
    password              = random_password.minio_application_password.result
    url                   = "http://${var.minio.host}:${local.port}"
    host                  = var.minio.host
    port                  = local.port
    bucket_name           = var.minio.bucket_name
    must_force_path_style = true
  }
}