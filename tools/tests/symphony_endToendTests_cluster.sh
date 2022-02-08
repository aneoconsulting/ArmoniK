#! /bin/bash

BASEDIR=$(dirname "$0")
pushd $BASEDIR
  BASEDIR=$(pwd -P)
popd

export MODE=""
export SERVER_NFS_IP=""
export STORAGE_TYPE="HostPath"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
DRY_RUN="${DRY_RUN:-0}"

pushd $(dirname $0) > /dev/null 2>&1
BASEDIR=$(pwd -P)
popd > /dev/null 2>&1

configuration=Debug

TestDir=${BASEDIR}/../../source/ArmoniK.Extensions.Csharp/SymphonyApi/ArmoniK.DevelopmentKit.SymphonyApi.Tests/EndToEnd.Tests/
cd ${TestDir}

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].hostname" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
export S3_BUCKET=$(aws s3api list-buckets | jq -r '.Buckets[0].Name')

function build()
{
    cd ${TestDir}
    dotnet publish --self-contained -c $configuration -r linux-x64 .
    #aws s3 sync --exclude "*" --include ArmoniK.EndToEndTests-v1.0.0.zip ../packages/ s3://$S3_BUCKET
    aws s3 cp ../packages/ArmoniK.EndToEndTests-v1.0.0.zip s3://$S3_BUCKET
    kubectl delete -n armonik $(kubectl get pods -n armonik -l service=compute-plane --no-headers=true -o name)
}

function execute()
{
    cd ${TestDir}
    dotnet bin/${configuration}/net5.0/linux-x64/ArmoniK.EndToEndTests.dll
}

function usage() {
  echo "Usage: $0 [option...]  with : " >&2
  echo
cat <<- EOF
        no option           : To build and Run tests
        -b | --build        : To build only test and package
        -r | --run          : To run only deploy package and test
        -a                  : To run only deploy package and test
EOF
  echo
  exit 0
}


DEFAULT=FALSE
MODE=All
function main()
{
    echo "Nb Arguments : $#"
    if [[ $# == 0 ]]; then
        build
        execute
        exit 0
    fi

    for i in "$@"; do
    case $i in
    -h | --help)
      usage
      exit
      shift # past argument=value
      ;;
    -r | --run)
      execute
      shift # past argument=value
      ;;
    -b | --build)
      build
      shift # past argument=value
      ;;

    -a | *)
      # unknown option
      build
      execute
      ;;
    esac
  done
}

main $@