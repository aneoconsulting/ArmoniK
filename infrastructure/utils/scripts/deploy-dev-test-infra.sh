#! /bin/bash

BASEDIR=$(dirname "$0")
pushd $BASEDIR
BASEDIR=$(pwd -P)
popd

MODE=""
NAMESPACE="armonik"
HOST_PATH="/data"
SERVER_NFS_IP=""
SHARED_STORAGE_TYPE="HostPath"
SOURCE_CODES_LOCALHOST_DIR=$BASEDIR/../../quick-deploy/localhost
MODIFY_PARAMETERS_SCRIPT=$BASEDIR/../../../tools/modify_parameters.py

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
        deploy-storage      : To deploy Storage independently on master machine. Available (Cluster or single node)
        deploy-monitoring   : To deploy monitoring independently on master machine. Available (Cluster or single node)
        deploy-armonik      : To deploy ArmoniK on master machine. Available (Cluster or single node)
        deploy-all          : To deploy Storage, Monitoring and ArmoniK
        redeploy-storage    : To REdeploy storage
        redeploy-monitoring : To REdeploy monitoring
        redeploy-armonik    : To REdeploy ArmoniK
        redeploy-all        : To REdeploy storage, monitoring and ArmoniK
        destroy-storage     : To destroy storage deployment only
        destroy-monitoring  : To destroy monitoring deployment only
        destroy-armonik     : To destroy Armonik deployment only
        destroy-all         : To destroy all storage, monitoring and ArmoniK in the same command
EOF
  echo "   -n, --namespace <NAMESPACE>"
  echo
  echo "   -p, --host-path <HOST_PATH>"
  echo
  echo "   -ip, --nfs-server-ip <SERVER_NFS_IP>"
  echo
  echo "   -s, --shared-storage-type <SHARED_STORAGE_TYPE>"
  echo
  cat <<-EOF
  Where --shared-storage-type should be :
        HostPath            : Use in localhost
        NFS                 : Use a NFS server
EOF
  echo
  exit 1
}

# Set environment variables
set_envvars() {
  export ARMONIK_KUBERNETES_NAMESPACE=$NAMESPACE
  export ARMONIK_SHARED_HOST_PATH=$HOST_PATH
  export ARMONIK_FILE_STORAGE_FILE=$SHARED_STORAGE_TYPE
  export ARMONIK_FILE_SERVER_IP=$SERVER_NFS_IP
}

# Create shared storage
create_host_path() {
  STORAGE_TYPE=$(echo "$SHARED_STORAGE_TYPE" | awk '{print tolower($0)}')
  if [ $STORAGE_TYPE == "hostpath" ]; then
    sudo mkdir -p $HOST_PATH
    sudo chown -R $USER:$USER $HOST_PATH
  fi
}

# Create Kubernetes namespace
create_kubernetes_namespace() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make create-namespace
}

# Prepare storage parameters
prepare_storage_parameters() {
  STORAGE_TYPE=$(echo "$SHARED_STORAGE_TYPE" | awk '{print tolower($0)}')
  python $MODIFY_PARAMETERS_SCRIPT \
    -kv shared_storage.file_storage_type=$STORAGE_TYPE \
    -kv shared_storage.file_server_ip=$SERVER_NFS_IP \
    -kv shared_storage.host_path=$HOST_PATH \
    $SOURCE_CODES_LOCALHOST_DIR/storage/parameters.tfvars \
    $BASEDIR/storage-parameters.tfvars.json
}

# Deploy storage
deploy_storage() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make deploy-storage PARAMETERS_FILE=$BASEDIR/storage-parameters.tfvars.json
}

# Deploy monitoring
deploy_monitoring() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make deploy-monitoring
}

# Deploy ArmoniK
deploy_armonik() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make deploy-armonik
}

# Deploy storage, monitoring and ArmoniK
deploy_all() {
  deploy_storage
  deploy_monitoring
  deploy_armonik
}

# Redeploy storage
redeploy_storage() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make destroy-storage
  make deploy-storage PARAMETERS_FILE=$BASEDIR/storage-parameters.tfvars.json
}

# Redeploy monitoring
redeploy_monitoring() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make destroy-monitoring
  make deploy-monitoring
}

# Redeploy ArmoniK
redeploy_armonik() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make destroy-armonik
  make deploy-armonik
}

# Redeploy storage, monitoring and ArmoniK
redeploy_all() {
  redeploy_storage
  redeploy_monitoring
  redeploy_armonik
}

# Destroy storage
destroy_storage() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make destroy-storage PARAMETERS_FILE=$BASEDIR/storage-parameters.tfvars.json
}

# Destroy monitoring
destroy_monitoring() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make destroy-monitoring
}

# Destroy ArmoniK
destroy_armonik() {
  cd $SOURCE_CODES_LOCALHOST_DIR
  make destroy-armonik
}

# Destroy storage, monitoring and ArmoniK
destroy_all() {
  destroy_armonik
  destroy_monitoring
  destroy_storage
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
    -p)
      HOST_PATH="$2"
      shift
      shift
      ;;
    --host-path)
      HOST_PATH="$2"
      shift
      shift
      ;;
    -n)
      NAMESPACE="$2"
      shift
      shift
      ;;
    --namespace)
      NAMESPACE="$2"
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

  # Set environment variables
  set_envvars

  # Create shared storage
  create_host_path

  # Create Kubernetes namespace
  create_kubernetes_namespace

  # Prepare storage parameters
  prepare_storage_parameters

  # Manage infra
  if [ -z $MODE ]; then
    usage
    exit
  elif [ $MODE == "deploy-storage" ]; then
    deploy_storage
  elif [ $MODE == "deploy-monitoring" ]; then
    deploy_monitoring
  elif [ $MODE == "deploy-armonik" ]; then
    deploy_armonik
  elif [ $MODE == "deploy-all" ]; then
    deploy_all
  elif [ $MODE == "redeploy-storage" ]; then
    redeploy_storage
  elif [ $MODE == "redeploy-monitoring" ]; then
    redeploy_monitoring
  elif [ $MODE == "redeploy-armonik" ]; then
    redeploy_armonik
  elif [ $MODE == "redeploy-all" ]; then
    redeploy_all
  elif [ $MODE == "destroy-storage" ]; then
    destroy_storage
  elif [ $MODE == "destroy-monitoring" ]; then
    destroy_monitoring
  elif [ $MODE == "destroy-armonik" ]; then
    destroy_armonik
  elif [ $MODE == "destroy-all" ]; then
    destroy_all
  else
    echo -e "\n${RED}$0 $@ where [ $MODE ] is not a correct Mode${NC}\n"
    usage
    exit
  fi
}

main $@
