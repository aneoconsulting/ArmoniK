#! /bin/sh

set -e

NAMESPACE=${NAMESPACE:-armonik}
MONGO_SECRET=${MONGO_SECRET:-mongodb-db-ps-secrets}
MONGO_HOST=${MONGO_HOST:-mongodb-db-ps-rs0.${NAMESPACE}.svc.cluster.local}
MONGO_PORT=${MONGO_PORT:-27017}
MONGO_RS=${MONGO_RS:-rs0}

cat <<EOF
Connect to MongoDB as admin inside the cluster.
Namespace:  $NAMESPACE
Host:       $MONGO_HOST:$MONGO_PORT  (rs=$MONGO_RS)
Secret:     $MONGO_SECRET

1 - Connect to a database:
      use <database>
2 - Example queries:
      db.TaskData.find().limit(3).pretty()
      db.TaskData.find({ SessionId: { \$eq: '<id>' } }).pretty()
      db.TaskData.find({ SessionId: { \$eq: '<id>' }, ExpectedOutputIds: { \$eq: '<id>' } }).pretty()

Docs: https://www.mongodb.com/docs/manual/reference/method/db.collection.find/
EOF

kubectl run -it --rm -n "$NAMESPACE" mongoshclient \
  --image=mongo:8 \
  --restart=Never \
  --overrides='
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": { "name": "mongoshclient", "namespace": "'"$NAMESPACE"'" },
  "spec": {
    "containers": [{
      "name": "mongosh",
      "image": "mongo:8",
      "stdin": true,
      "tty": true,
      "command": ["bash", "-c"],
      "args": ["mongosh \"mongodb://${MONGO_ADMIN_USERNAME}:${MONGO_ADMIN_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/admin?replicaSet=${MONGO_RS}\""],
      "env": [
        { "name": "MONGO_ADMIN_USERNAME", "valueFrom": { "secretKeyRef": { "name": "'"$MONGO_SECRET"'", "key": "MONGODB_DATABASE_ADMIN_USER" } } },
        { "name": "MONGO_ADMIN_PASSWORD", "valueFrom": { "secretKeyRef": { "name": "'"$MONGO_SECRET"'", "key": "MONGODB_DATABASE_ADMIN_PASSWORD" } } },
        { "name": "MONGO_HOST",           "value": "'"$MONGO_HOST"'" },
        { "name": "MONGO_PORT",           "value": "'"$MONGO_PORT"'" },
        { "name": "MONGO_RS",             "value": "'"$MONGO_RS"'" }
      ]
    }],
    "restartPolicy": "Never"
  }
}'
