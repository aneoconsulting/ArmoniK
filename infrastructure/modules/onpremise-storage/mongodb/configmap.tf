# Envvars
locals {
  mongodb_js = <<EOF

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
resource "kubernetes_config_map" "mongodb_js" {
  metadata {
    name      = "mongodb-configmap"
    namespace = var.namespace
  }
  data = {
    "mongo-init.js" = local.mongodb_js
  }
}

resource "local_file" "mongodb_js_file" {
  content  = local.mongodb_js
  filename = "${path.root}/generated/configmaps/mongodb/mongodb.js"
}
