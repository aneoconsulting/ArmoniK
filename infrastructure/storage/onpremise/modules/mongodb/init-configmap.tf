resource "random_string" "mongodb_admin_user" {
  length  = 8
  special = false
  number  = false
}

resource "random_password" "mongodb_admin_password" {
  length  = 16
  special = false
}

resource "random_string" "mongodb_application_user" {
  length  = 8
  special = false
  number  = false
}

resource "random_password" "mongodb_application_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = var.mongodb.credentials_admin_secret
    namespace = var.mongodb.credentials_admin_namespace
  }

  data = {
    "${var.mongodb.credentials_admin_key_username}" = "${random_string.mongodb_admin_user.result}"
    "${var.mongodb.credentials_admin_key_password}" = "${random_password.mongodb_admin_password.result}"
  }

  type = var.mongodb.credentials_admin_type
}

resource "kubernetes_secret" "mongodb_user" {
  metadata {
    name      = var.mongodb.credentials_user_secret
    namespace = var.mongodb.credentials_user_namespace
  }

  data = {
    "${var.mongodb.credentials_user_key_username}" = "${random_string.mongodb_application_user.result}"
    "${var.mongodb.credentials_user_key_password}" = "${random_password.mongodb_application_password.result}"
  }

  type = var.mongodb.credentials_user_type
}

# Envvars
locals {
  init_mongodb_js = <<EOF

db = db.getSiblingDB("database");
db.createCollection("sample");
db.sample.insert({test:1})
db.createUser(
   {
     user: "${random_string.mongodb_application_user.result}",
     pwd: "${random_password.mongodb_application_password.result}",
     roles: [ { role: "readWrite", db: "database" }, { role: "dbAdmin", db: "database" } ]
   }
);
db.sample.drop()

EOF
}

# configmap with all the variables
resource "kubernetes_config_map" "init_mongodb_js" {
  metadata {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
  data = {
    "mongo-init.js" = local.init_mongodb_js
  }
}

resource "local_file" "init_mongodb_js_file" {
  content  = local.init_mongodb_js
  filename = "./generated/configmaps/init_mongodb.js"
}