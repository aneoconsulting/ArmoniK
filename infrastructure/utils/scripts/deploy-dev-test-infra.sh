#! /bin/bash

BASEDIR=$(dirname "$0")

export ARMONIK_STORAGE_NAMESPACE=armonik-storage
export ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY=../../credentials
export ARMONIK_STORAGE_REDIS_SECRET_NAME=redis-storage-secret
export ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY=../../credentials
export ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME=activemq-storage-secret
export ARMONIK_NAMESPACE=armonik
export ARMONIK_MONITORING_NAMESPACE=armonik-monitoring
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=../credentials
export ARMONIK_REDIS_SECRET_NAME=redis-storage-secret
export ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY=../credentials
export ARMONIK_EXTERNAL_REDIS_SECRET_NAME=external-redis-storage-secret
export ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY=../credentials
export ARMONIK_ACTIVEMQ_SECRET_NAME=activemq-storage-secret
export MODE=""
export SERVER_NFS_IP=""

# usage
usage() {
  echo "Usage: $0 [option...]" >&2
  echo
  echo "   -m=, --mode=<destroy | destroy-armonik | destroy-storage | deploy-on-single-node | deploy-on-cluster | deploy-storage| armonik-single-node | armonik-cluster>"
  echo "   -ip=, --master-ip=<SERVER_NFS_IP>"
  echo
  exit 1
}

# Clean
destroy_storage() {
  cd $BASEDIR/../../storage/onpremise
  terraform destroy -auto-approve
  make clean
  kubectl delete namespace $ARMONIK_STORAGE_NAMESPACE
  cd -
}

destroy_armonik() {
  cd $BASEDIR/../../armonik
  terraform destroy -auto-approve
  make clean
  kubectl delete namespace $ARMONIK_NAMESPACE
  cd -
}

# deploy storage
deploy_storage() {
  cd $BASEDIR/../../storage/onpremise
  kubectl create namespace $ARMONIK_STORAGE_NAMESPACE
  kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key --from-file=ca_cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/ca.crt
  kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE --from-file=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties
  terraform apply -var-file=parameters.tfvars -auto-approve
  cd -
}

# storage endpoint urls
endpoint_urls() {
  cd $BASEDIR/../../storage/onpremise
  export ACTIVEMQ_HOST=$(terraform output -json activemq_endpoint_url | jq -r '.host')
  export ACTIVEMQ_PORT=$(terraform output -json activemq_endpoint_url | jq -r '.port')
  export MONGODB_URL=$(terraform output -json mongodb_endpoint_url | jq -r '.url')
  export REDIS_URL=$(terraform output -json redis_endpoint_url | jq -r '.url')
  export SHARED_STORAGE_HOST=$1
  cd -
}

# create configuration file
configuration_file() {
  python $BASEDIR/../../../tools/modify_parameters.py \
    --storage-object "Redis" \
    --storage-table "MongoDB" \
    --storage-queue "Amqp" \
    --storage-lease-provider "MongoDB" \
    --storage-external "Redis" \
    --mongodb-url $MONGODB_URL \
    --mongodb-kube-secret "" \
    --activemq-host $ACTIVEMQ_HOST \
    --activemq-port $ACTIVEMQ_PORT \
    --activemq-kube-secret $ARMONIK_ACTIVEMQ_SECRET_NAME \
    --shared-host $SHARED_STORAGE_HOST \
    --redis-url $REDIS_URL \
    --redis-kube-secret $ARMONIK_REDIS_SECRET_NAME \
    --external-url $REDIS_URL \
    --external-kube-secret $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
    --control-plane-image "dockerhubaneo/armonik_control" \
    --control-plane-tag "0.2.0-redis.29.20d9f60" \
    --polling-agent-image "dockerhubaneo/armonik_pollingagent" \
    --polling-agent-tag "0.2.0-redis.29.20d9f60" \
    --worker-image "dockerhubaneo/armonik_worker_dll" \
    --worker-tag "0.1.1" \
    --storage-shared-type $1 \
    $BASEDIR/../../armonik/parameters.tfvars \
    ./parameters.tfvars.json
}

# deploy armonik
deploy_armonik() {
  # install hcl2
  pip install python-hcl2
  endpoint_urls $SERVER_NFS_IP
  if [ $1 == "armonik-cluster" ] || [ $1 == "deploy-on-cluster" ]; then
    configuration_file "NFS"
  elif [ $1 == "armonik-single-node" ] || [ $1 == "deploy-on-single-node" ]; then
    configuration_file "HostPath"
  fi

  cd $BASEDIR/../../armonik
  kubectl create namespace $ARMONIK_NAMESPACE
  kubectl create namespace $ARMONIK_MONITORING_NAMESPACE
  kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=ca_cert_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/ca.crt --from-file=certificate_pfx=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
  kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=ca_cert_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/ca.crt --from-file=certificate_pfx=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
  kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=amqp_credentials=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json
  terraform apply -var-file=../utils/scripts/parameters.tfvars.json -auto-approve
  cd -
}

# Main
cd $BASEDIR/../../storage/onpremise
terraform init
cd -
cd $BASEDIR/../../armonik
terraform init
cd -

for i in "$@"; do
  case $i in
  -h | --help)
    usage
    exit
    shift # past argument=value
    ;;
  -m=* | --mode=*)
    MODE="${i#*=}"
    shift # past argument=value
    ;;
  -ip=* | --nfs-server-ip=*)
    SERVER_NFS_IP="${i#*=}"
    shift # past argument=value
    ;;
  --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
  *)
    # unknown option
    ;;
  esac
done

if [ -z $MODE ]; then
  usage
  exit
elif [ $MODE == "destroy-armonik" ]; then
  destroy_armonik
elif [ $MODE == "destroy-storage" ]; then
  destroy_storage
elif [ $MODE == "destroy" ]; then
  destroy_storage
  destroy_armonik
elif [ $MODE == "deploy-storage" ]; then
  deploy_storage
elif [ $MODE == "armonik-single-node" ] || [ $MODE == "armonik-cluster" ] || [ $MODE == "deploy-on-single-node" ] || [ ]$MODE == "deploy-on-cluster" ]; then
  if [ $MODE == "deploy-on-single-node" ] || [ ]$MODE == "deploy-on-cluster" ]; then
    deploy_storage
  fi
  deploy_armonik $MODE
else
  usage
  exit
fi
