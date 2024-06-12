#! /bin/sh

set -e

cat <<EOF
**********************************************************************************************************************
***** This script allows you to connect to mongo directly from inside the cluster => useful for AWS installation *****
**********************************************************************************************************************

- You can execute requests ex :
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
          "mongosh --tlsCAFile /mongodb/chain.pem --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls -u $MONGO_USERNAME -p $MONGO_USER_PASSWORD mongodb+srv://mongodb-armonik-headless.armonik.svc.cluster.local/database"
        ],
        "env": [
          {
            "name": "MONGO_USERNAME",
            "valueFrom": {
              "secretKeyRef": {
                "name": "mongodb-user",
                "key": "username"
              }
            }
          },
          {
            "name": "MONGO_USER_PASSWORD",
            "valueFrom": {
              "secretKeyRef": {
                "name": "mongodb-user",
                "key": "password"
              }
            }
          }
        ],
        "volumeMounts": [
          {
            "name": "mongodb-secret-volume",
            "mountPath": "/mongodb/"
          }
        ],
        "resources": {}
      }
    ],
    "volumes": [
      {
        "name": "mongodb-secret-volume",
        "secret": {
          "secretName": "mongodb"
        }
      }
    ],
    "dnsPolicy": "ClusterFirst",
    "restartPolicy": "Always"
  },
  "status": {}
}
'
