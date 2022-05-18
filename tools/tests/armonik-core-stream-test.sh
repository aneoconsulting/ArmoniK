#!/bin/bash
set -e

###############################################################################
# Container image for control plane: dockerhubaneo/armonik_control            #
# Container Image for polling agent: dockerhubaneo/armonik_pollingagent       #
# Container Image for worker: dockerhubaneo/armonik_core_stream_test_worker   #
# Container Image for metrics exporter: dockerhubaneo/armonik_control_metrics #
# Container image for client: dockerhubaneo/armonik_core_stream_test_client   #
###############################################################################

BASEDIR=$(dirname "$0")
INPUT_PARAMETERS_FILE=""
GrpcClient__Endpoint=""
ARMONIK_NAME_SPACE="armonik"
CLIENT_IMAGE="dockerhubaneo/armonik_core_stream_test_client"
CLIENT_TAG="0.5.9"

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
  exit 1
}

# Url of control plane
get_control_plane_url() {
  # Retrieve from the file of parameters
  if [ -f "${INPUT_PARAMETERS_FILE}" ]; then
    GrpcClient__Endpoint=$(cat "${INPUT_PARAMETERS_FILE}" | jq -r '.armonik.ingress.control_plane_url')
  fi

  # Retrieve from the control plane parameter
  if [ -z ${GrpcClient__Endpoint} ]; then
    CPIP=$(kubectl get svc ingress -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].ip" --no-headers=true)
    if [ "${CPIP}" == "<none>" ]; then
      CPIP=$(kubectl get svc ingress -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
      if [ "${CPIP}" == "<none>" ]; then
        NODE_NAME=$(kubectl get pods --selector="service=ingress" -n ${ARMONIK_NAME_SPACE} -o custom-columns="NODE:.spec.nodeName" --no-headers=true)
        if [ "${NODE_NAME}" == "<none>" ]; then
          echo "The URL of control plane is empty !"
          exit 1
        fi
        CPIP=$(kubectl get nodes -o wide --no-headers=true | grep -w ${NODE_NAME} | awk '{print $6}')
        CPPort=$(kubectl get svc ingress -n armonik -o custom-columns="PORT:.spec.ports[1].nodePort" --no-headers=true)
      fi
    fi
    CPPort=$(kubectl get svc ingress -n armonik -o custom-columns="PORT:.spec.ports[1].port" --no-headers=true)
    GrpcClient__Endpoint="http://${CPIP}:${CPPort}"
  fi
}

# Execute client
launch_client(){
  docker run --rm -e GrpcClient__Endpoint="${GrpcClient__Endpoint}" ${CLIENT_IMAGE}:${CLIENT_TAG}
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
      GrpcClient__Endpoint="$2"
      shift
      shift
      ;;
    --control-plane-url)
      GrpcClient__Endpoint="$2"
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
  if [ -z ${GrpcClient__Endpoint} ]; then
      echo "The URL of control plane is empty !"
      exit 1
  fi

  # Execute client
  echo "*****"
  echo "***** Launch a client \"armonik_core_stream_test_client\" with control plane URL=${GrpcClient__Endpoint}"
  echo "*****"
  launch_client
}

main $@
