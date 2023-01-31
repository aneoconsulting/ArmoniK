resource "random_string" "minio_application_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "minio_application_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "s3_user" {
  metadata {
    name      = "s3-user"
    namespace = var.namespace
  }
  data = {
    username = random_string.minio_application_user.result
    password = random_password.minio_application_password.result
  }
  type = "kubernetes.io/basic-auth"
}