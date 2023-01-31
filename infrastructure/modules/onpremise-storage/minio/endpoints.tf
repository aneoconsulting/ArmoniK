resource "kubernetes_secret" "s3_endpoints" {
  metadata {
    name      = "s3-endpoints"
    namespace = var.namespace
  }
  data = {
    url                   = "http://${var.minio.host}:${local.port}"
    host                  = var.minio.host
    port                  = local.port
    bucket_name           = var.minio.bucket_name
    must_force_path_style = true
  }
}