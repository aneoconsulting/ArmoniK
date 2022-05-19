resource "random_string" "mq_admin_user" {
  length  = 8
  special = false
  number  = false
}

resource "random_password" "mq_admin_password" {
  length  = 16
  special = false
}

resource "random_string" "mq_application_user" {
  length  = 8
  special = false
  number  = false
}

resource "random_password" "mq_application_password" {
  length  = 16
  special = false
}

resource "random_password" "mq_keystore_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "activemq_admin" {
  metadata {
    name      = "activemq-admin"
    namespace = var.namespace
  }
  data = {
    username = random_string.mq_admin_user.result
    password = random_password.mq_admin_password.result
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "activemq_user" {
  metadata {
    name      = "activemq-user"
    namespace = var.namespace
  }
  data = {
    username = random_string.mq_application_user.result
    password = random_password.mq_application_password.result
  }
  type = "kubernetes.io/basic-auth"
}
