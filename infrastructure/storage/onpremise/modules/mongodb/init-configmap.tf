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
    name      = "mongodb-admin"
    namespace = "armonik"
  }

  data = {
    username = "${random_string.mongodb_admin_user.result}"
    password = "${random_password.mongodb_admin_password.result}"
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mongodb_user" {
  metadata {
    name      = "mongodb-user"
    namespace = "armonik"
  }

  data = {
    username = "${random_string.mongodb_application_user.result}"
    password = "${random_password.mongodb_application_password.result}"
  }

  type = "kubernetes.io/basic-auth"
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