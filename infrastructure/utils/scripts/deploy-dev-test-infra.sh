#! /bin/bash

BASEDIR=$(dirname "$0")
pushd "${BASEDIR}"
BASEDIR=$(pwd -P)
popd

MODE=""
NAMESPACE="armonik"
HOST_PATH=$(realpath "${HOME}/data")
SERVER_NFS_IP=""
SHARED_STORAGE_TYPE="HostPath"
SOURCE_CODES_LOCALHOST_DIR=$(realpath "${BASEDIR}/../../quick-deploy/localhost")
MODIFY_PARAMETERS_SCRIPT=$(realpath "${BASEDIR}/../../../tools/modify_parameters.py")
CONTROL_PLANE_IMAGE="dockerhubaneo/armonik_control"
POLLING_AGENT_IMAGE="dockerhubaneo/armonik_pollingagent"
WORKER_IMAGE="dockerhubaneo/armonik_worker_dll"
METRICS_EXPORTER_IMAGE="dockerhubaneo/armonik_control_metrics"
CORE_TAG="0.5.0"
WORKER_TAG="0.5.0"
HPA_MAX_REPLICAS=5
HPA_MIN_REPLICAS=1
STORAGE_PARAMETERS_FILE="${SOURCE_CODES_LOCALHOST_DIR}/storage/parameters.tfvars"
MONITORING_PARAMETERS_FILE="${SOURCE_CODES_LOCALHOST_DIR}/monitoring/parameters.tfvars"
ARMONIK_PARAMETERS_FILE="${SOURCE_CODES_LOCALHOST_DIR}/armonik/parameters.tfvars"
GENERATED_STORAGE_PARAMETERS_FILE="${BASEDIR}/storage-parameters.tfvars.json"
GENERATED_MONITORING_PARAMETERS_FILE="${BASEDIR}/monitoring-parameters.tfvars.json"
GENERATED_ARMONIK_PARAMETERS_FILE="${BASEDIR}/armonik-parameters.tfvars.json"

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
        clean-storage       : To clean and deleted generated files for storage deployment only
        clean-monitoring    : To clean and deleted generated files for monitoring deployment only
        clean-armonik       : To clean and deleted generated files for Armonik deployment only
        clean-all           : To clean and deleted generated files for all storage, monitoring and ArmoniK in the same command
EOF
  echo "   -n, --namespace <NAMESPACE>"
  echo
  echo "   --host-path <HOST_PATH>"
  echo
  echo "   --nfs-server-ip <SERVER_NFS_IP>"
  echo
  echo "   --shared-storage-type <SHARED_STORAGE_TYPE>"
  cat <<-EOF
  Where --shared-storage-type should be :
        HostPath            : Use in localhost
        NFS                 : Use a NFS server
EOF
  echo
  echo "   --control-plane-image <CONTROL_PLANE_IMAGE>"
  echo
  echo "   --polling-agent-image <POLLING_AGENT_IMAGE>"
  echo
  echo "   --worker-image <WORKER_IMAGE>"
  echo
  echo "   --metrics-exporter-image <METRICS_EXPORTER_IMAGE>"
  echo
  echo "   --core-tag <CORE_TAG>"
  echo
  echo "   --worker-tag <WORKER_TAG>"
  echo
  echo "   --hpa-min-replicas <HPA_MIN_REPLICAS>"
  echo
  echo "   --hpa-max-replicas <HPA_MAX_REPLICAS>"
  echo
  exit 1
}

# Set environment variables
set_envvars() {
  export ARMONIK_KUBERNETES_NAMESPACE="${NAMESPACE}"
  export ARMONIK_SHARED_HOST_PATH="${HOST_PATH}"
  export ARMONIK_FILE_STORAGE_FILE="${SHARED_STORAGE_TYPE}"
  export ARMONIK_FILE_SERVER_IP="${SERVER_NFS_IP}"
}

# Create shared storage
create_host_path() {
  STORAGE_TYPE=$(echo "${SHARED_STORAGE_TYPE}" | awk '{print tolower($0)}')
  if [ "${STORAGE_TYPE}" == "hostpath" ]; then
    mkdir -p "${HOST_PATH}"
  fi
}

# Create Kubernetes namespace
create_kubernetes_namespace() {
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make create-namespace
}

# Prepare storage parameters
prepare_storage_parameters() {
  STORAGE_TYPE=$(echo "${SHARED_STORAGE_TYPE}" | awk '{print tolower($0)}')
  python "${MODIFY_PARAMETERS_SCRIPT}" \
    -kv shared_storage.file_storage_type="${STORAGE_TYPE}" \
    -kv shared_storage.file_server_ip="${SERVER_NFS_IP}" \
    -kv shared_storage.host_path="${HOST_PATH}" \
    "${STORAGE_PARAMETERS_FILE}" \
    "${GENERATED_STORAGE_PARAMETERS_FILE}"
}

# Prepare monitoring parameters
prepare_monitoring_parameters() {
  python "${MODIFY_PARAMETERS_SCRIPT}" \
    -kv monitoring.metrics_exporter.image="${METRICS_EXPORTER_IMAGE}" \
    -kv monitoring.metrics_exporter.tag="${CORE_TAG}" \
    "${MONITORING_PARAMETERS_FILE}" \
    "${GENERATED_MONITORING_PARAMETERS_FILE}"
}

# Prepare armonik parameters
prepare_armonik_parameters() {
  python "${MODIFY_PARAMETERS_SCRIPT}" \
    -kv control_plane.image="${CONTROL_PLANE_IMAGE}" \
    -kv control_plane.tag="${CORE_TAG}" \
    -kv compute_plane[*].polling_agent.image="${POLLING_AGENT_IMAGE}" \
    -kv compute_plane[*].polling_agent.tag="${CORE_TAG}" \
    -kv compute_plane[*].worker[*].image="${WORKER_IMAGE}" \
    -kv compute_plane[*].worker[*].tag="${WORKER_TAG}" \
    -kv compute_plane[*].hpa.min_replicas="${HPA_MIN_REPLICAS}" \
    -kv compute_plane[*].hpa.max_replicas="${HPA_MAX_REPLICAS}" \
    "${ARMONIK_PARAMETERS_FILE}" \
    "${GENERATED_ARMONIK_PARAMETERS_FILE}"
}

# Deploy storage
deploy_storage() {
  # Prepare storage parameters
  prepare_storage_parameters

  # Deploy
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make deploy-storage PARAMETERS_FILE="${GENERATED_STORAGE_PARAMETERS_FILE}"
}

# Deploy monitoring
deploy_monitoring() {
  # Prepare monitoring parameters
  prepare_monitoring_parameters

  # Deploy
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make deploy-monitoring PARAMETERS_FILE="${GENERATED_MONITORING_PARAMETERS_FILE}"
}

# Deploy ArmoniK
deploy_armonik() {
  # Prepare armonik parameters
  prepare_armonik_parameters

  # Deploy
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make deploy-armonik PARAMETERS_FILE="${GENERATED_ARMONIK_PARAMETERS_FILE}"
}

# Deploy storage, monitoring and ArmoniK
deploy_all() {
  deploy_storage
  deploy_monitoring
  deploy_armonik
}

# Destroy storage
destroy_storage() {
  if [ ! -f "${GENERATED_STORAGE_PARAMETERS_FILE}" ]; then
    prepare_storage_parameters
  fi

  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make destroy-storage PARAMETERS_FILE="${GENERATED_STORAGE_PARAMETERS_FILE}"
}

# Destroy monitoring
destroy_monitoring() {
  if [ ! -f "${GENERATED_MONITORING_PARAMETERS_FILE}" ]; then
    prepare_monitoring_parameters
  fi

  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make destroy-monitoring PARAMETERS_FILE="${GENERATED_MONITORING_PARAMETERS_FILE}"
}

# Destroy ArmoniK
destroy_armonik() {
  if [ ! -f "${GENERATED_ARMONIK_PARAMETERS_FILE}" ]; then
    prepare_armonik_parameters
  fi

  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make destroy-armonik PARAMETERS_FILE="${GENERATED_ARMONIK_PARAMETERS_FILE}"
}

# Destroy storage, monitoring and ArmoniK
destroy_all() {
  destroy_armonik
  destroy_monitoring
  destroy_storage
}

# Redeploy storage
redeploy_storage() {
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  destroy_storage
  deploy_storage
}

# Redeploy monitoring
redeploy_monitoring() {
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  destroy_monitoring
  deploy_monitoring
}

# Redeploy ArmoniK
redeploy_armonik() {
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  destroy_armonik
  deploy_armonik
}

# Redeploy storage, monitoring and ArmoniK
redeploy_all() {
  destroy_all
  deploy_all
}

# Clean storage
clean_storage() {
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make clean-storage
  rm -f "${GENERATED_STORAGE_PARAMETERS_FILE}"
}

# Clean monitoring
clean_monitoring() {
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make clean-monitoring
  rm -f "${GENERATED_MONITORING_PARAMETERS_FILE}"
}

# Clean ArmoniK
clean_armonik() {
  cd "${SOURCE_CODES_LOCALHOST_DIR}"
  make clean-armonik
  rm -f "${GENERATED_ARMONIK_PARAMETERS_FILE}"
}

# Clean storage, monitoring and ArmoniK
clean_all() {
  clean_armonik
  clean_monitoring
  clean_storage
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
    --nfs-server-ip)
      SERVER_NFS_IP="$2"
      SHARED_STORAGE_TYPE="NFS"
      shift
      shift
      ;;
    --shared-storage-type)
      SHARED_STORAGE_TYPE="$2"
      shift
      shift
      ;;
    --host-path)
      HOST_PATH=$(realpath "$2")
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
    --control-plane-image)
      CONTROL_PLANE_IMAGE="$2"
      shift
      shift
      ;;
    --polling-agent-image)
      POLLING_AGENT_IMAGE="$2"
      shift
      shift
      ;;
    --worker-image)
      WORKER_IMAGE="$2"
      shift
      shift
      ;;
    --metrics-exporter-image)
      METRICS_EXPORTER_IMAGE="$2"
      shift
      shift
      ;;
    --core-tag)
      CORE_TAG="$2"
      shift
      shift
      ;;
    --worker-tag)
      WORKER_TAG="$2"
      shift
      shift
      ;;
    --hpa-min-replicas)
      HPA_MIN_REPLICAS="$2"
      shift
      shift
      ;;
    --hpa-max-replicas)
      HPA_MAX_REPLICAS="$2"
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
  elif [ $MODE == "clean-storage" ]; then
    clean_storage
  elif [ $MODE == "clean-monitoring" ]; then
    clean_monitoring
  elif [ $MODE == "clean-armonik" ]; then
    clean_armonik
  elif [ $MODE == "clean-all" ]; then
    clean_all
  else
    echo -e "\n${RED}$0 $@ where [ $MODE ] is not a correct Mode${NC}\n"
    usage
    exit
  fi
}

main $@
