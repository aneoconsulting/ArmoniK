#! /bin/bash

BASEDIR=$(dirname "$0")
pushd $BASEDIR
  BASEDIR=$(pwd -P)
popd

export MODE=""
export SERVER_NFS_IP=""

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
DRY_RUN="${DRY_RUN:-0}"

# Let shell functions inherit ERR trap.  Same as `set -E'.
set -o errtrace
# Trigger error when expanding unset variables.  Same as `set -u'.
set -o nounset
#  Trap non-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR
#  NOTE1: - 9/KILL cannot be trapped.
#+        - 0/EXIT isn't trapped because:
#+          - with ERR trap defined, trap would be called twice on error
#+          - with ERR trap defined, syntax errors exit with status 0, not 2
#  NOTE2: Setting ERR trap does implicit `set -o errexit' or `set -e'.

trap onexit 1 2 3 15 ERR

#--- onexit() -----------------------------------------------------
#  @param $1 integer  (optional) Exit status.  If not set, use `$?'

function onexit() {
    local exit_status=${1:-$?}
    if [[ $exit_status != 0 ]]; then
	echo -e "${RED}Exiting $0 with $exit_status${NC}"
	exit $exit_status
    fi

}

function execute()
{
    echo -e "${GREEN}[EXEC] : $@${NC}"
    err=0
    if [[ $DRY_RUN == 0 ]]; then
	$@
	onexit
    fi
}

function isWSL()
{
  if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
      return 0
  else
      return 1
  fi
}

function getHostName()
{
  sed -nr '0,/127.0.0.1/ s/.*\s+(.*)/\1/p' /etc/hosts
}

# usage
usage() {
  echo "Usage: $0 [option...]" >&2
  echo
  echo "   -m, --mode <destroy | destroy-armonik | destroy-storage | deploy-localhost | deploy-cluster | deploy-storage| armonik-localhost | armonik-cluster | redeploy-localhost | redeploy-armonik >"
cat <<- EOF
  Where --mode should be :
        destroy             : To destroy all storage and armonik in the same command
        destroy-armonik     : To destroy Armonik deployment only
        destroy-storage     : To destroy storage deployment only
        deploy-localhost    : To deploy both Storage and Armonik on a single node or VM or localhost machine
        deploy-cluster      : To deploy both storage and Armonik on a multi nodes servers (on premise)
        deploy-storage      : To deploy Storage independently on master machine. Available (Cluster or single node)
        armonik-localhost   : To deploy armonik on a single node or VM, localhost
        armonik-cluster     : To deploy armonik on a multi node cluster (on premise)
        redeploy-localhost  : To REdeploy both storage and armonik on a single node or VM or localhost machine
        redeploy-armonik    : To REdeploy armonik on a single node or VM or localhost machine

EOF
  echo "   -ip, --master-ip <SERVER_NFS_IP>"
  echo
  exit 1
}

# Clean
destroy_storage() {
  cd $BASEDIR/../../storage/onpremise
  execute terraform destroy -auto-approve
  execute make clean
  execute kubectl delete namespace $ARMONIK_STORAGE_NAMESPACE
  cd -
}

destroy_armonik() {
  cd $BASEDIR/../../armonik
  execute terraform destroy -auto-approve
  execute make clean
  execute kubectl delete namespace $ARMONIK_NAMESPACE
  cd -
}

# deploy storage
deploy_storage() {
  terraform_init_storage
  cd $BASEDIR/../../storage/onpremise
  kubectl create namespace $ARMONIK_STORAGE_NAMESPACE || true
  kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key --from-file=ca_cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/ca.crt  || true
  kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE --from-file=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties  || true
  execute terraform apply -var-file=parameters.tfvars -auto-approve
  cd -
}

# storage endpoint urls
endpoint_urls() {
  pushd $BASEDIR/../../storage/onpremise > /dev/null 2>&1
  export ACTIVEMQ_HOST=$(terraform output -json activemq_endpoint_url | jq -r '.host')
  export ACTIVEMQ_PORT=$(terraform output -json activemq_endpoint_url | jq -r '.port')
  export MONGODB_URL=$(terraform output -json mongodb_endpoint_url | jq -r '.url')
  export REDIS_URL=$(terraform output -json redis_endpoint_url | jq -r '.url')
  export SHARED_STORAGE_HOST=${1:-""}
  execute echo "Get Hostname for Shared Storage: ${SHARED_STORAGE_HOST}"
  popd > /dev/null 2>&1
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
    --shared-host "$SHARED_STORAGE_HOST" \
    --redis-url $REDIS_URL \
    --redis-kube-secret $ARMONIK_REDIS_SECRET_NAME \
    --external-url $REDIS_URL \
    --external-kube-secret $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
    --storage-shared-type $1 \
    $BASEDIR/../../armonik/parameters.tfvars \
    $BASEDIR/parameters.tfvars.json
}

# deploy armonik
deploy_armonik() {
  terraform_init_armonik
  # install hcl2
  execute pip install python-hcl2
  execute echo "Get Optional IP for Shared Storage: ${SERVER_NFS_IP}"
  endpoint_urls $SERVER_NFS_IP
  if [[ $1 == "armonik-cluster" || $1 == "deploy-cluster" || $1 == "redeploy-cluster" ]]; then
    configuration_file "NFS"
  elif [[ $1 == "armonik-localhost" || $1 == "deploy-localhost" || $1 == "redeploy-localhost" ]]; then
    configuration_file "HostPath"
  fi

  cd $BASEDIR/../../armonik
  kubectl create namespace $ARMONIK_NAMESPACE  || true
  kubectl create namespace $ARMONIK_MONITORING_NAMESPACE  || true
  kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=ca_cert_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/ca.crt --from-file=certificate_pfx=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx  || true
  kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=ca_cert_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/ca.crt --from-file=certificate_pfx=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx  || true
  kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_NAMESPACE --from-file=amqp_credentials=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json  || true
  execute terraform apply -var-file=$BASEDIR/parameters.tfvars.json -auto-approve
  cd -
}

# Main
function terraform_init_storage()
{
  pushd $BASEDIR/../../storage/onpremise > /dev/null 2>&1
  execute echo "change to directory : $(pwd -P)"
  execute terraform init
  popd > /dev/null 2>&1
}

function terraform_init_armonik()
{
  pushd $BASEDIR/../../armonik > /dev/null 2>&1
  execute echo "change to directory : $(pwd -P)"
  execute terraform init
  popd > /dev/null 2>&1
}

function main()
{
  for i in "$@"; do
    case $i in
    -h | --help)
      usage
      exit
      shift # past argument=value
      ;;
    -m)
      MODE="$2"
      shift
      shift
      ;;
    --mode)
      MODE="$2"
      shift
      shift
      ;;
    -ip)
      SERVER_NFS_IP="$2"
      shift
      shift
      ;;
    --nfs-server-ip)
      SERVER_NFS_IP="$2"
      shift
      shift
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

  # source envvars
  source $BASEDIR/../envvars-storage.conf
  source $BASEDIR/../envvars-armonik.conf

  # Manage infra
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
  elif [[ $MODE == "redeploy-localhost" || $MODE == "redeploy-cluster" ]]; then
    destroy_storage
    destroy_armonik
    deploy_storage
    deploy_armonik $MODE
  elif [[ $MODE == "armonik-localhost" || $MODE == "armonik-cluster" || $MODE == "deploy-localhost" || $MODE == "deploy-cluster" ]]; then
    if [[ $MODE == "deploy-localhost" || $MODE == "deploy-cluster" ]]; then
      deploy_storage
    fi
    deploy_armonik $MODE
  else
    usage
    exit
  fi
}

main $@