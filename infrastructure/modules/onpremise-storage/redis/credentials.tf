resource "random_password" "redis_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "redis_user" {
  metadata {
    name      = "redis-user"
    namespace = var.namespace
  }
  data = {
    username = ""
    password = random_password.redis_password.result
  }
  type = "kubernetes.io/basic-auth"
}