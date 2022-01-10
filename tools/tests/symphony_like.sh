#!/bin/bash

cd ../../source/ArmoniK.Samples
git submodule update --init
git pull origin main
git checkout main

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].ip" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort

#export Grpc__Endpoint="http://54.190.176.172:5001"

cd Samples/SymphonyLike/
dotnet publish --self-contained -r linux-x64 SymphonyLike.sln

sudo mkdir -p /data
sudo chown -R $USER:$USER /data
cp packages/ArmoniK.Samples.SymphonyPackage-v1.0.0.zip /data

#scp -i packages/ArmoniK.Samples.SymphonyPackage-v1.0.0.zip ~/.ssh/cluster-key ec2-user@54.188.89.4:/data

cd ArmoniK.Samples.SymphonyClient/
dotnet bin/Debug/net5.0/linux-x64/ArmoniK.Samples.SymphonyClient.dll
