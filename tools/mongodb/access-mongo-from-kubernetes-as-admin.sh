#! /bin/sh

set -e

cat <<EOF
**********************************************************************************************************************
***** This script allows you to connect to mongo directly from inside the cluster => useful for AWS installation *****
**********************************************************************************************************************

1 - Firstly you have to connect to db :
  use database

2 - You can execute requests ex :
- Display all TaskData :
  db.TaskData.find().limit(3).pretty()
- Filter by  session / output :
  db.TaskData.find({ SessionId: { \$eq : '7eafe4e3-0aa2-46ef-8ce6-bf9e365c5449' }, ExpectedOutputIds: { \$eq : 'a600dca5-b672-4177-9b4a-880dbcefee4e'}}).pretty()

more informations here : https://www.mongodb.com/docs/manual/reference/method/db.collection.find/

EOF

kubectl run -it --rm -n armonik mongoshclient --image=rtsp/mongosh --overrides='
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "creationTimestamp": null,
    "labels": {
      "run": "mongoshclient"
    },
    "name": "mongoshclient",
    "namespace": "armonik"
  },
  "spec": {
    "containers": [
      {
        "name": "mongosh",
        "image": "rtsp/mongosh",
        "stdin": true,
        "tty": true,
        "command": [
          "bash",
          "-c"
        ],
        "args": [
          "mongosh -u $MONGO_ADMIN_USERNAME -p $MONGO_ADMIN_PASSWORD 'mongodb://mongodb-db-ps-rs0.armonik.svc.cluster.local:27017/admin?replicaSet=rs0'"
        ],
        "env": [
          {
            "name": "MONGO_ADMIN_USERNAME",
            "valueFrom": {
              "secretKeyRef": {
                "name": "mongodb-db-ps-secrets",
                "key": "MONGODB_DATABASE_ADMIN_USER"
              }
            }
          },
          {
            "name": "MONGO_ADMIN_PASSWORD",
            "valueFrom": {
              "secretKeyRef": {
                "name": "mongodb-db-ps-secrets",
                "key": "MONGODB_DATABASE_ADMIN_PASSWORD"
              }
            }
          }
        ],
        "resources": {}
      }
    ],
    "volumes": [],
    "dnsPolicy": "ClusterFirst",
    "restartPolicy": "Always"
  },
  "status": {}
}
'
