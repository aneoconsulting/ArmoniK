#! /bin/sh

#  MongoDB aggregation query to count processed tasks by pod.
#
# Purpose:
# This script facilitates access to a MongoDB instance running in a Kubernetes cluster.
# It retrieves the necessary credentials and certificates from Kubernetes secrets and
# connects to the MongoDB service using the `mongosh` Docker image. The script also
# includes a sample MongoDB aggregation query to count processed tasks by pod.
#
# Usage:
# ./script.sh
#
# Process:
# 1. Retrieves the MongoDB username and password from Kubernetes secrets in the "armonik"
#    namespace, decoding them from base64.
# 2. Fetches the MongoDB certificate chain from Kubernetes secrets and saves it as
#    `mongodb_chain.pem`.
# 3. Obtains the Cluster IP of the MongoDB service using a label selector.
# 4. Executes a MongoDB aggregation query to count the number of processed tasks by
#    pod, printing the results in JSON format.
# 5. Runs the `mongosh` Docker container, mounting the certificate chain and connecting
#    to the MongoDB instance using the retrieved credentials.
#
# Requirements:
# - kubectl must be installed and configured to interact with the Kubernetes cluster.
# - Docker must be installed to run the `mongosh` container.
# - The `rtsp/mongosh` Docker image must be available.

# ACESS to monogodb as user
MPASS="$(kubectl get secret -n armonik mongodb-user -o jsonpath="{.data.password}" | base64 --decode)"
MUSER="$(kubectl get secret -n armonik mongodb-user -o jsonpath="{.data.username}" | base64 --decode)"
kubectl get secret -n armonik mongodb-user-certificates -o jsonpath="{.data.chain\.pem}" | base64 --decode > ./mongodb_chain.pem
MONGO_IP="$(kubectl get svc --selector="service=mongodb" -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)"

# Get the number of processed tasks by pod
echo 'db.TaskData.aggregate([{$group : {_id:"$OwnerPodId", count:{$sum:1}}}, {$sort: {count:1}}]).forEach(printjson);'

docker run -it -v "$(pwd)/mongodb_chain.pem:/chain.pem" --rm rtsp/mongosh mongosh --tlsCAFile /chain.pem --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls -u "$MUSER" -p "$MPASS" "mongodb://$MONGO_IP:27017/database" #--eval 'db.serverStatus()'
