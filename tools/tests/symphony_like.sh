#!/bin/bash

BASEDIR=$(dirname "$0")

cd $BASEDIR/../../source/ArmoniK.Samples

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
nuget_cache=$(dotnet nuget locals global-packages --list | awk '{ print $2 }')

cd Samples/SymphonyLike/
echo rm -rf ${nuget_cache}/armonik.*
rm -rf $(dotnet nuget locals global-packages --list | awk '{ print $2 }')/armonik.*
dotnet publish -c Debug --self-contained -r linux-x64 SymphonyLike.sln

if [ ! -d "/data" ]; then
  echo  "Need to create Data folder for application"
  sudo mkdir -p /data
  sudo chown -R $USER:$USER /data
fi

cp packages/ArmoniK.Samples.SymphonyPackage-v1.0.0.zip /data
kubectl delete -n armonik $(kubectl get pods -n armonik -l service=compute-plane --no-headers=true -o name)

cd ArmoniK.Samples.SymphonyClient/
dotnet bin/Debug/net5.0/linux-x64/ArmoniK.Samples.SymphonyClient.dll
