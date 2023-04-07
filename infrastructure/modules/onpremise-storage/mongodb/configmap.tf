# Envvars
locals {
  mongodb_js = <<EOF

db = db.getSiblingDB("database");
db.createCollection("sample");
db.sample.insertOne({test:1})
db.createUser(
   {
     user: "${random_string.mongodb_application_user.result}",
     pwd: "${random_password.mongodb_application_password.result}",
     roles: [ { role: "readWrite", db: "database" }, { role: "dbAdmin", db: "database" } ]
   }
);
db.sample.drop()

EOF

  init_replica_js = <<EOF

rs.initiate({
  _id :  "rs0",
  members: [
%{for i, service in kubernetes_service.mongodb~}
    { _id:  ${i}, host:  "${service.metadata.0.name}.${service.metadata.0.namespace}:${service.spec.0.port.0.port}" },
%{endfor~}
  ]
})

EOF

  mongo_start_sh = <<EOF

# TODO: put this file at another place
CLUSTER_KEY=/data/db/cluster.key

if [ ! -e $CLUSTER_KEY ] ; then
  cp /cluster/cluster.key $CLUSTER_KEY
  chmod 400 $CLUSTER_KEY
fi

/usr/local/bin/docker-entrypoint.sh mongod \
  --dbpath=/data/db \
  --port=27017 \
  --bind_ip=localhost,$${HOSTNAME} \
  --tlsMode=requireTLS \
  --tlsDisabledProtocols=TLS1_0 \
  --tlsCertificateKeyFile=/mongodb/mongodb.pem \
  --keyFile $CLUSTER_KEY \
  --auth \
  --noscripting \
  --replSet=rs0 &

sleep 15

if [ "$1" == "0" ] ; then
  mongosh \
    --username ${random_string.mongodb_admin_user.result} \
    --password ${random_password.mongodb_admin_password.result} \
    --tlsCAFile /mongodb/chain.pem \
    --tlsAllowInvalidHostnames \
    --tlsAllowInvalidCertificates \
    --tls \
    localhost:27017/admin /start/initreplica.js
fi



wait

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

resource "kubernetes_config_map" "mongo_start_sh" {
  metadata {
    name      = "mongodb-start-configmap"
    namespace = var.namespace
  }
  data = {
    "mongostart.sh"  = local.mongo_start_sh
    "initreplica.js" = local.init_replica_js
  }
}

resource "local_file" "mongodb_js_file" {
  content  = local.mongodb_js
  filename = "${path.root}/generated/configmaps/mongodb/mongodb.js"
}

resource "local_file" "init_replica_js" {
  content  = local.init_replica_js
  filename = "${path.root}/generated/configmaps/mongodb/initreplica.js"
}