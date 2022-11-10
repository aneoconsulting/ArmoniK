# Generate username
resource "random_string" "user" {
  length           = 8
  special          = true
  numeric          = false
  override_special = "-._~"
}

# Generate password
resource "random_password" "password" {
  length           = 16
  special          = true
  lower            = true
  upper            = true
  numeric          = true
  override_special = "!@#$%&*()-_+.{}<>?"
}

resource "kubernetes_secret" "activemq_user" {
  metadata {
    name      = "activemq-user"
    namespace = var.namespace
  }
  data = {
    username = local.username
    password = local.password
  }
  type = "kubernetes.io/basic-auth"
}