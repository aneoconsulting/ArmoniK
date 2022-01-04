#!/bin/bash

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].ip" --no-headers=true)
export ReIP=$(kubectl get svc redis -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].ip" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export RePort=$(kubectl get svc redis -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
export Redis__EndpointUrl=$ReIP:$RePort
export Redis__SslHost="127.0.0.1"
export Redis__Timeout=3000
export Redis__CaCertPath=../../infrastructure/localhost/credentials/ca.crt
export Redis__ClientPfxPath=../../infrastructure/localhost/credentials/certificate.pfx

cd ../../source/ArmoniK.Samples/Samples/HtcMock/Client/src
dotnet build "ArmoniK.Samples.HtcMock.Client.csproj" -c Release
dotnet bin/Release/net5.0/ArmoniK.Samples.HtcMock.Client.dll