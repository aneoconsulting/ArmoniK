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

kubectl replace --force -f mongo_client_in_k8s.yaml
echo "Waiting for pod to be in Ready state..."

kubectl wait -n armonik pod/mongoshclient --for=condition=Ready
kubectl exec -it -n armonik mongoshclient -- bash -c 'mongosh --tlsCAFile /mongodb/chain.pem --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" mongodb://mongodb:27017'
kubectl delete -f mongo_client_in_k8s.yaml

