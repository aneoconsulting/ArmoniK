#! /bin/bash

BASEDIR=$(dirname "$0")
pushd $BASEDIR
BASEDIR=$(pwd -P)
popd

export MODE=""
export SERVER_NFS_IP=$(hostname -I | awk '{print $1}')
export SHARED_STORAGE_TYPE="HostPath"

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

function execute() {
  echo -e "${GREEN}[EXEC] : $@${NC}"
  err=0
  if [[ $DRY_RUN == 0 ]]; then
    $@
    onexit
  fi
}

function isWSL() {
  if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
    return 0
  else
    return 1
  fi
}

function getHostName() {
  sed -nr '0,/127.0.0.1/ s/.*\s+(.*)/\1/p' /etc/hosts
}

# usage
usage() {
  echo "Usage: $0 [option...]" >&2
  echo
  echo "   -m, --mode <Possible options below>"
  cat <<-EOF
  Where --mode should be :
        destroy-all         : To destroy all storage and armonik in the same command
        destroy-armonik     : To destroy Armonik deployment only
        destroy-storage     : To destroy storage deployment only
        deploy-storage      : To deploy Storage independently on master machine. Available (Cluster or single node)
        deploy-armonik      : To deploy armonik
        deploy-all          : To deploy both Storage and Armonik
        redeploy-storage    : To REdeploy storage
        redeploy-armonik    : To REdeploy armonik
        redeploy-all        : To REdeploy both storage and armonik

EOF
  echo "   -ip, --nfs-server-ip <SERVER_NFS_IP>"
  echo
  echo "   -s, --shared-storage-type <SHARED_STORAGE_TYPE>"
  cat <<-EOF
  Where --shared-storage-type should be :
        HostPath            : Use in localhost
        NFS                 : Use a NFS server
        AWS_EBS             : Use an AWS Elastic Block Store
EOF
  echo
  exit 1
}

# Clean
destroy_storage() {
  terraform_init_storage
  cd $BASEDIR/../../storage/onpremise
  execute terraform destroy -auto-approve
  execute make clean
  # execute kubectl delete namespace $ARMONIK_STORAGE_NAMESPACE
  cd -
}

destroy_armonik() {
  terraform_init_armonik
  cd $BASEDIR/../../armonik
  execute terraform destroy -auto-approve
  execute make clean
  # execute kubectl delete namespace $ARMONIK_NAMESPACE
  cd -
}

# deploy storage
deploy_storage() {
  terraform_init_storage
  cd $BASEDIR/../../storage/onpremise
  execute terraform apply -var-file=parameters.tfvars -auto-approve
  cd -
}

# storage endpoint urls
endpoint_urls() {
  pushd $BASEDIR/../../storage/onpremise >/dev/null 2>&1
  export ACTIVEMQ_HOST=$(terraform output -json activemq_endpoint_url | jq -r '.host')
  export ACTIVEMQ_PORT=$(terraform output -json activemq_endpoint_url | jq -r '.port')
  export MONGODB_HOST=$(terraform output -json mongodb_endpoint_url | jq -r '.host')
  export MONGODB_PORT=$(terraform output -json mongodb_endpoint_url | jq -r '.port')
  export REDIS_URL=$(terraform output -json redis_endpoint_url | jq -r '.url')
  export SHARED_STORAGE_HOST=${1:-""}
  execute echo "Get Hostname for Shared Storage: \"${SHARED_STORAGE_HOST}\""
  popd >/dev/null 2>&1
}

# create configuration file
configuration_file() {
  python $BASEDIR/../../../tools/modify_parameters.py \
    --storage-object "Redis" \
    --storage-table "MongoDB" \
    --storage-queue "Amqp" \
    --storage-lease-provider "MongoDB" \
    --storage-external "Redis" \
    --storage-shared-type $SHARED_STORAGE_TYPE \
    --mongodb-host $MONGODB_HOST \
    --mongodb-port $MONGODB_PORT \
    --mongodb-kube-secret $ARMONIK_MONGODB_SECRET_NAME \
    --activemq-host $ACTIVEMQ_HOST \
    --activemq-port $ACTIVEMQ_PORT \
    --activemq-kube-secret $ARMONIK_ACTIVEMQ_SECRET_NAME \
    --redis-url $REDIS_URL \
    --redis-kube-secret $ARMONIK_REDIS_SECRET_NAME \
    --shared-host $SHARED_STORAGE_HOST \
    --external-url $REDIS_URL \
    --external-kube-secret $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
    $BASEDIR/../../armonik/storage-parameters.tfvars \
    $BASEDIR/storage-parameters.tfvars.json

  python $BASEDIR/../../../tools/modify_parameters.py \
    $BASEDIR/../../armonik/armonik-parameters.tfvars \
    $BASEDIR/armonik-parameters.tfvars.json

  python $BASEDIR/../../../tools/modify_parameters.py \
    $BASEDIR/../../armonik/monitoring-parameters.tfvars \
    $BASEDIR/monitoring-parameters.tfvars.json
}

# deploy armonik
deploy_armonik() {
  terraform_init_armonik
  # install hcl2
  execute pip install python-hcl2
  execute echo "Get Optional IP for Shared Storage: \"${SERVER_NFS_IP}\""
  endpoint_urls $SERVER_NFS_IP

  configuration_file ${SHARED_STORAGE_TYPE}

  cd $BASEDIR/../../armonik
  execute terraform apply -var-file $BASEDIR/storage-parameters.tfvars.json -var-file $BASEDIR/armonik-parameters.tfvars.json -var-file $BASEDIR/monitoring-parameters.tfvars.json -auto-approve
  cd -
}

function terraform_init_storage() {
  pushd $BASEDIR/../../storage/onpremise >/dev/null 2>&1
  execute echo "change to directory : $(pwd -P)"
  execute terraform init
  popd >/dev/null 2>&1
}

function terraform_init_armonik() {
  pushd $BASEDIR/../../armonik >/dev/null 2>&1
  execute echo "change to directory : $(pwd -P)"
  execute terraform init
  popd >/dev/null 2>&1
}

create_kube_secrets() {
  cd $BASEDIR/../../../tools/install
  bash init_kube.sh
  cd -
}

# Main
function main() {
  for i in "$@"; do
    case $i in
    -h | --help)
      usage
      exit
      shift
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
      SHARED_STORAGE_TYPE="NFS"
      shift
      shift
      ;;
    --nfs-server-ip)
      SERVER_NFS_IP="$2"
      SHARED_STORAGE_TYPE="NFS"
      shift
      shift
      ;;
    -s)
      SHARED_STORAGE_TYPE="$2"
      shift
      shift
      ;;
    --shared-storage-type)
      SHARED_STORAGE_TYPE="$2"
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

  # Create Kubernetes secrets
  create_kube_secrets

  # Manage infra
  if [ -z $MODE ]; then
    usage
    exit
  elif [ $MODE == "destroy-armonik" ]; then
    destroy_armonik
  elif [ $MODE == "destroy-storage" ]; then
    destroy_storage
  elif [ $MODE == "destroy-all" ]; then
    destroy_storage
    destroy_armonik
  elif [ $MODE == "deploy-storage" ]; then
    deploy_storage
  elif [ $MODE == "deploy-armonik" ]; then
    deploy_armonik
  elif [ $MODE == "deploy-all" ]; then
    deploy_storage
    deploy_armonik
  elif [[ $MODE == "redeploy-storage" ]]; then
    destroy_storage
    deploy_storage
  elif [[ $MODE == "redeploy-armonik" ]]; then
    destroy_armonik
    deploy_armonik
  elif [[ $MODE == "redeploy-all" ]]; then
    destroy_storage
    destroy_armonik
    deploy_storage
    deploy_armonik
  else
    echo -e "\n${RED}$0 $@ where [ $MODE ] is not a correct Mode${NC}\n"
    usage
    exit
  fi
}

main $@
