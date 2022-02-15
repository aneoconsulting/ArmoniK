#!/bin/bash

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

TestDir=${BASEDIR}/../../source/ArmoniK.Samples/Samples/GridServerLike/

cd ${TestDir}

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
nuget_cache=$(dotnet nuget locals global-packages --list | awk '{ print $2 }')

if [ ! -d "/data" ]; then
    echo  "Need to create Data folder for application"
    sudo mkdir -p /data
fi
if [ ! -w "/data" ]; then
  sudo chown -R $USER:$USER /data
fi

function build()
{
    cd ${TestDir}
    echo rm -rf ${nuget_cache}/armonik.*
    rm -rf $(dotnet nuget locals global-packages --list | awk '{ print $2 }')/armonik.*
    find \( -iname obj -o -iname bin \) -exec rm -rf {} +

    dotnet publish --self-contained -c Debug -r linux-x64 .
}

function deploy()
{
    cd ${TestDir}
    cp packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip /data

    kubectl delete -n armonik $(kubectl get pods -n armonik -l service=compute-plane --no-headers=true -o name)
}

function execute()
{
    echo "cd ${TestDir}/Armonik.Samples.GridServer.Client"
    cd ${TestDir}/Armonik.Samples.GridServer.Client

    echo dotnet bin/net5.0/linux-x64/ArmoniK.Samples.GridServer.Client.dll
    dotnet bin/net5.0/linux-x64/ArmoniK.Samples.GridServer.Client.dll

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
	deploy
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

