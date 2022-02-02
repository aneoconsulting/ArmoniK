#!/bin/bash

BASEDIR=$(dirname "$0")

cd $BASEDIR/../../source/ArmoniK.Samples

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort

cd Samples/GridServerLike/
dotnet publish --self-contained -r linux-x64 DataSynapseLike.sln

sudo mkdir -p /data
sudo chown -R $USER:$USER /data
cp packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip /data

cd ArmoniK.Samples.GridServer.Client/
dotnet bin/net5.0/linux-x64/ArmoniK.Samples.GridServer.Client.dll
