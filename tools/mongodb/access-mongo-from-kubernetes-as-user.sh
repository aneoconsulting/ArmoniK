#! /bin/sh

set -e

NAMESPACE=${NAMESPACE:-armonik}
MONGO_SECRET=${MONGO_SECRET:-mongodb-connection-string}

cat <<EOF
Connect to MongoDB inside the cluster.
Namespace:  $NAMESPACE
Secret:     $MONGO_SECRET

Example queries:
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
      "args": ["mongosh \"$MONGODB_URI\""],
      "env": [{
        "name": "MONGODB_URI",
        "valueFrom": { "secretKeyRef": { "name": "'"$MONGO_SECRET"'", "key": "uri" } }
      }]
    }],
    "restartPolicy": "Never"
  }
}'
