#!/bin/bash

DEFAULT_TAG="v1"
DEFAULT_PARTITION="helloworld"

usage() {
    echo "Usage: $0 [-t TAG] [-p PARTITION] [-a USE_AUTH]"
    echo "TAG: Core tag (defaults to $DEFAULT_TAG)"
    echo "PARTITION: partition name (defaults to $DEFAULT_PARTITION)"
    echo "USE_AUTH: use auth credentials (defaults to false)"
    exit 1
}

# Parse optional arguments
while getopts ":t:p:a:" opt; do
  case ${opt} in
    t )
      ARG_TAG=$OPTARG
      ;;
    p )
      ARG_PARTITION=$OPTARG
      ;;
    a )
     ARG_AUTH=$OPTARG
     ;;
    \? )
      usage
      ;;
  esac
done

VERSION="${ARG_TAG:-$DEFAULT_TAG}"

PARTITION="${ARG_PARTITION:-$DEFAULT_PARTITION}"

GRPC_CLIENT_END_POINT="http://ad40cf8e2ba0e445089111759c59d159-1007761890.eu-west-3.elb.amazonaws.com:5001"

CERTS_DIR="/home/ubuntu/ArmoniK/infrastructure/quick-deploy/aws/generated/certificates/ingress/"

if [ "x${ARG_AUTH}" == "xtrue" ]; then
AUTH_OPTS=$(cat<<EOF
  -u $UID:$(id -g)
  -v $CERTS_DIR:/app/certs
  -e GrpcClient__CaCert=/app/certs/ca.crt
  -e GrpcClient__CertP12=/app/certs/client.submitter.p12
  -e GrpcClient__OverrideTargetName=armonik.local
  -e GrpcClient__AllowUnsafeConnection=true
EOF
)
fi

echo $AUTH_OPTS

docker run --rm \
  $AUTH_OPTS \
  dockerhubaneo/armonik_demo_helloworld_client:$VERSION \
  --endpoint $GRPC_CLIENT_END_POINT --partition $PARTITION
