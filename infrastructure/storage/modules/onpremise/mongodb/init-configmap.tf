# Envvars
locals {
  init_mongodb_js = <<EOF

db = db.getSiblingDB("database");
db.createCollection("sample");
db.sample.insert({test:1})
db.createUser(
   {
     user: "admintest",
     pwd: "admin*12709876543",
     roles: [ { role: "readWrite", db: "database" }, { role: "dbAdmin", db: "database" } ]
   }
);
db.sample.drop()
db.dropUser("tmpAdmin")

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