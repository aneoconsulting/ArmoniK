#!/bin/bash

cd ../../source/ArmoniK.Samples
git submodule update --init

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].ip" --no-headers=true)
export ReIP=$(kubectl get svc redis -n armonik-storage -o custom-columns="IP:.status.loadBalancer.ingress[*].ip" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export RePort=$(kubectl get svc redis -n armonik-storage -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
export Redis__EndpointUrl=$ReIP:$RePort
export Redis__SslHost="127.0.0.1"
export Redis__Timeout=3000
export Redis__CaCertPath=/home/sysadmin/Armonik/armonik/infrastructure/credentials/ca.crt
export Redis__ClientPfxPath=/home/sysadmin/Armonik/armonik/infrastructure/credentials/certificate.pfx

cd Samples/HtcMock/Client/src
dotnet build "ArmoniK.Samples.HtcMock.Client.csproj" -c Release
dotnet bin/Release/net5.0/ArmoniK.Samples.HtcMock.Client.dll