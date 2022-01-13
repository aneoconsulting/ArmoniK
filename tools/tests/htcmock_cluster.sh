#!/bin/bash

cd ../../source/ArmoniK.Samples
git submodule update --init
git pull origin main
git checkout main

export Grpc__Endpoint="http://35.88.68.211:32622"
export Redis__EndpointUrl="34.221.12.201:32108"
export Redis__SslHost="127.0.0.1"
export Redis__Timeout=3000

cd Samples/HtcMock/Client/src
export Redis__CaCertPath=../../../../../../infrastructure/credentials/ca.crt
export Redis__ClientPfxPath=../../../../../../infrastructure/credentials/certificate.pfx

dotnet build "ArmoniK.Samples.HtcMock.Client.csproj" -c Release
dotnet bin/Release/net5.0/ArmoniK.Samples.HtcMock.Client.dll