#!/bin/bash

pushd $(dirname $0) > /dev/null 2>&1
BASEDIR=$(pwd -P)
popd > /dev/null 2>&1

configuration=Debug

cd ${BASEDIR}/../../source/ArmoniK.Extensions.Csharp/SymphonyApi/ArmoniK.DevelopmentKit.SymphonyApi.Tests/EndToEnd.Tests/

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort

dotnet publish --self-contained -c $configuration -r linux-x64

if [ ! -d "/data" ]; then
    sudo mkdir -p /data
    sudo chown -R $USER:$USER /data
fi

cp ../packages/ArmoniK.EndToEndTests-v1.0.0.zip /data

dotnet bin/${configuration}/net5.0/linux-x64/ArmoniK.EndToEndTests.dll