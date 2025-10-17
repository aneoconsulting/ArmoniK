#!/bin/bash

DEFAULT_TAG="0.0.0.0-local"
DEFAULT_URL="http://armonik.control.submitter:1080"
DEFAULT_MODE="core"
DEFAULT_PARTITION="TestPartition0"

usage() {
    echo "Usage: $0 [-t TAG] [-m MODE] [-p PARTITION]"
    echo "TAG: Core tag (defaults to $DEFAULT_TAG)"
    echo "MODE: core or full (defaults to $DEFAULT_MODE)"
    echo "PARTITION: partition name (defaults to $DEFAULT_PARTITION)"
    exit 1
}

# Parse optional arguments
while getopts ":t:m:p:" opt; do
  case ${opt} in
    t )
      ARG_TAG=$OPTARG
      ;;
    m )
      ARG_MODE=$OPTARG
      ;;
    p )
      ARG_PARTITION=$OPTARG
      ;;
    \? )
      usage
      ;;
  esac
done

VERSION="${ARG_TAG:-$DEFAULT_TAG}"

MODE="${ARG_MODE:-$DEFAULT_MODE}"

PARTITION="${ARG_PARTITION:-$DEFAULT_PARTITION}"

GRPC_CLIENT_END_POINT="${AK_CONTROL_PLANE_URL:-$DEFAULT_URL}"

if [ "x${MODE}" = xcore ]; then
  DOCKER_RUN_OPS="--net armonik_network"
else
  DOCKER_RUN_OPS=""
fi

#docker build -t  dockerhubaneo/armonik_core_htcmock_test_client:$VERSION -f ./Tests/HtcMock/Client/src/Dockerfile ./

docker run $DOCKER_RUN_OPS --rm \
  -e HtcMock__NTasks=10000 \
  -e HtcMock__TotalCalculationTime=00:00:10 \
  -e HtcMock__DataSize=1 \
  -e HtcMock__MemorySize=1 \
  -e HtcMock__SubTasksLevels=4 \
  -e HtcMock__Partition=$PARTITION \
  -e HtcMock__EnableFastCompute=true \
  -e HtcMock__TaskRpcException="" \
  -e GrpcClient__Endpoint=$GRPC_CLIENT_END_POINT \
  dockerhubaneo/armonik_core_htcmock_test_client:$VERSION
