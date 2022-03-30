#!/bin/bash
set -e

##########################################################################################
# Container image for control plane    : dockerhubaneo/armonik_control                   #
# Container Image for polling agent    : dockerhubaneo/armonik_pollingagent              #
# Container Image for worker           : dockerhubaneo/armonik_core_htcmock_test_worker  #
# Container Image for metrics exporter : dockerhubaneo/armonik_control_metrics           #
# Container image for client           : dockerhubaneo/armonik_core_htcmock_test_client  #
##########################################################################################

########################################################################################################################################################################
# Parameters of the HTCMock:                                                                                                                                           #
# --------------------------                                                                                                                                           #
# SubTasksLevels       : number of levels in the graph of tasks                                                                                                        #
# TotalNbSubTasks      : total number of tasks in all levels (the aggregation tasks are not taken into account in this parameter!)                                     #
# MemorySize           : size in memory for a task in ? (KB, kiB, ...)                                                                                                               #
# TotalCalculationTime : total computation time for TotalNbSubTasks tasks (the computation times for aggregation tasks are not taken into account in this parameter !) #
# DataSize             : ?                                                                                                                                             #
########################################################################################################################################################################


BASEDIR=$(dirname "$0")
INPUT_PARAMETERS_FILE=""
Grpc__Endpoint=""
ARMONIK_NAME_SPACE="armonik"
CLIENT_IMAGE="dockerhubaneo/armonik_core_htcmock_test_client"
CLIENT_TAG="0.5.4"
HtcMock__TotalCalculationTime="00:00:00.100"
HtcMock__DataSize=1
HtcMock__MemorySize=1
HtcMock__SubTasksLevels=4
HtcMock__TotalNbSubTasks=1000

# usage
usage() {
  echo "Usage: $0 [option...]" >&2
  echo
  echo "   -p, --parameters-file <FILE-PATH-OF-ARMONIK-PARAMETERS>"
  echo
  echo "   -c, --control-plane-url <URL-OF-CONTROL-PLANE>"
  echo
  echo "   -n, --namespace <KUBERNETES-NAMESPACE-OF-CONTROL-PALNE>"
  echo
  echo "   -i, --client-image <CLIENT-CONTAINER-IMAGE>"
  echo
  echo "   -t, --client-tag <CLIENT-CONTAINER-TAG>"
  echo
  echo "   --total-calculation-time <TotalCalculationTime>"
  echo
  echo "   --data-size <DataSize>"
  echo
  echo "   --memory-size <MemorySize>"
  echo
  echo "   --sub-tasks-levels <SubTasksLevels>"
  echo
  echo "   --total-nb-sub-tasks <TotalNbSubTasks>"
  echo
  exit 1
}

# Url of control plane
get_control_plane_url() {
  # Retrieve from the file of parameters
  if [ -f "${INPUT_PARAMETERS_FILE}" ]; then
    Grpc__Endpoint=$(cat "${INPUT_PARAMETERS_FILE}" | jq '.armonik.control_plane_url')
  fi

  # Retrieve from the control plane parameter
  if [ -z ${Grpc__Endpoint} ]; then
    CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].hostname" --no-headers=true)
    if [ "${CPIP}" == "<none>" ]; then
      CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
      if [ "${CPIP}" == "<none>" ]; then
        NODE_NAME=$(kubectl get pods --selector="service=control-plane" -n ${ARMONIK_NAME_SPACE} -o custom-columns="NODE:.spec.nodeName" --no-headers=true)
        if [ "${NODE_NAME}" == "<none>" ]; then
          echo "The URL of control plane is empty !"
          exit 1
        fi
        CPIP=$(kubectl get nodes -o wide --no-headers=true | grep -w ${NODE_NAME} | awk '{print $6}')
        CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].nodePort" --no-headers=true)
      fi
    fi
    CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
    Grpc__Endpoint="http://${CPIP}:${CPPort}"
  fi
}

# Execute client
launch_client(){
  docker run --rm -e Grpc__Endpoint="${Grpc__Endpoint}" -e HtcMock__NTasks="${HtcMock__TotalNbSubTasks}" -e HtcMock__TotalCalculationTime="${HtcMock__TotalCalculationTime}" -e HtcMock__DataSize="${HtcMock__DataSize}" -e HtcMock__MemorySize="${HtcMock__MemorySize}" -e HtcMock__SubTasksLevels="${HtcMock__SubTasksLevels}" ${CLIENT_IMAGE}:${CLIENT_TAG}
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
    -p)
      INPUT_PARAMETERS_FILE=$(realpath "$2")
      shift
      shift
      ;;
    --parameters-file)
      INPUT_PARAMETERS_FILE=$(realpath "$2")
      shift
      shift
      ;;
    -c)
      Grpc__Endpoint="$2"
      shift
      shift
      ;;
    --control-plane-url)
      Grpc__Endpoint="$2"
      shift
      shift
      ;;
    -n)
      ARMONIK_NAME_SPACE="$2"
      shift
      shift
      ;;
    --namespace)
      ARMONIK_NAME_SPACE="$2"
      shift
      shift
      ;;
    -i)
      CLIENT_IMAGE="$2"
      shift
      shift
      ;;
    --client-image)
      CLIENT_IMAGE="$2"
      shift
      shift
      ;;
    -t)
      CLIENT_TAG="$2"
      shift
      shift
      ;;
    --client-tag)
      CLIENT_TAG="$2"
      shift
      shift
      ;;
    --sub-tasks-levels)
      HtcMock__SubTasksLevels="$2"
      shift
      shift
      ;;
    --memory-size)
      HtcMock__MemorySize="$2"
      shift
      shift
      ;;
    --data-size)
      HtcMock__DataSize="$2"
      shift
      shift
      ;;
    --total-calculation-time)
      HtcMock__TotalCalculationTime="$2"
      shift
      shift
      ;;
    --total-nb-sub-tasks)
      HtcMock__TotalNbSubTasks="$2"
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

  # Url of control plane
  get_control_plane_url
  if [ -z ${Grpc__Endpoint} ]; then
      echo "The URL of control plane is empty !"
      exit 1
  fi

  # Execute client
  echo "***** Launch a client \"armonik_core_htcmock_test_client\" with :"
  echo "      Control plane URL=${Grpc__Endpoint}"
  echo "      HtcMock__TotalCalculationTime=${HtcMock__TotalCalculationTime}"
  echo "      HtcMock__DataSize=${HtcMock__DataSize}"
  echo "      HtcMock__MemorySize=${HtcMock__MemorySize}"
  echo "      HtcMock__SubTasksLevels=${HtcMock__SubTasksLevels}"
  echo "      HtcMock__TotalNbSubTasks=${HtcMock__TotalNbSubTasks}"
  echo "*****"
  launch_client
}

main $@
