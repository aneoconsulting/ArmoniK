#! /bin/bash
# -h : ./deploy-dev-test-infra.sh <MODE> <IP_MASTER_NODE>
# MODE: destroy / single-node / cluster

BASEDIR=$(dirname "$0")
echo "$BASEDIR"

export ARMONIK_STORAGE_NAMESPACE=armonik-storage
export ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY=../../credentials
export ARMONIK_STORAGE_REDIS_SECRET_NAME=redis-storage-secret
export ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY=../../credentials
export ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME=activemq-storage-secret
export ARMONIK_NAMESPACE=armonik
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=../credentials
export ARMONIK_REDIS_SECRET_NAME=redis-storage-secret
export ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY=../credentials
export ARMONIK_EXTERNAL_REDIS_SECRET_NAME=external-redis-storage-secret
export ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY=../credentials
export ARMONIK_ACTIVEMQ_SECRET_NAME=activemq-storage-secret

# Clean
cd $BASEDIR/../../storage/onpremise
make destroy
make clean
kubectl delete namespace $ARMONIK_STORAGE_NAMESPACE
cd -

cd $BASEDIR/../../armonik
terraform init
terraform destroy -auto-approve
make clean
kubectl delete namespace $ARMONIK_NAMESPACE
cd -

# destroy all
if [ $1 == "destroy" ]
then
  exit
fi

# Storage
cd $BASEDIR/../../storage/onpremise
kubectl create namespace $ARMONIK_STORAGE_NAMESPACE
kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key --from-file=ca_cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/ca.crt
kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE --from-file=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties
make all

# Storage endpoints
terraform init
export ACTIVEMQ_HOST=$(terraform output -json activemq_endpoint_url | jq -r '.host')
export ACTIVEMQ_PORT=$(terraform output -json activemq_endpoint_url | jq -r '.port')
export MONGODB_URL=$(terraform output -json mongodb_endpoint_url | jq -r '.url')
export REDIS_URL=$(terraform output -json redis_endpoint_url | jq -r '.url')
export SHARED_STORAGE_HOST=$2
cd -

# Deploy armonik
cd $BASEDIR/../../armonik
kubectl create namespace $ARMONIK_NAMESPACE
kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=ca_cert_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/ca.crt --from-file=certificate_pfx=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=ca_cert_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/ca.crt --from-file=certificate_pfx=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=amqp_credentials=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json
terraform init

if [ $1 == "single-node" ]
then
  terraform apply -auto-approve \
  -var='storage={"object":"MongoDB", "table":"MongoDB", "queue":"Amqp", "lease_provider":"MongoDB", "shared":"HostPath", "external":"Redis"}' \
  -var='storage_endpoint_url={"mongodb":{"url":"$MONGODB_URL", "secret":""}, "redis":{"url":"", "secret":""}, "activemq":{"host":"$ACTIVEMQ_HOST", "port":"$ACTIVEMQ_PORT", "secret":"activemq-storage-secret"}, "shared":{"host":"", "secret":"", "path":"/data"}, "external":{"url":"$REDIS_URL", "secret":"external-redis-storage-secret"}}'
elif [ $1 == "cluster" ]
then
  echo $ACTIVEMQ_HOST
   echo $ACTIVEMQ_PORT
   echo $MONGODB_URL
   echo $REDIS_URL
   echo $SHARED_STORAGE_TYPE_CLUSTER
   echo $SHARED_STORAGE_HOST
else
  exit
fi