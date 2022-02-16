#!/bin/bash

cd ../../source/ArmoniK.Samples

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].hostname" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
#export S3_BUCKET=$(aws s3api list-buckets --output json | jq -r '.Buckets[0].Name')

export Redis__EndpointUrl="34.221.12.201:32108"
export Redis__SslHost="127.0.0.1"
export Redis__Timeout=3000

cd Samples/HtcMock/Client/src
export Redis__CaCertPath=../../../../../../infrastructure/credentials/ca.crt
export Redis__ClientPfxPath=../../../../../../infrastructure/credentials/certificate.pfx

dotnet build "ArmoniK.Samples.HtcMock.Client.csproj" -c Release
dotnet bin/Release/net5.0/ArmoniK.Samples.HtcMock.Client.dll