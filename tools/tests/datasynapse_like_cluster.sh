#!/bin/bash

cd ../../source/ArmoniK.Samples
git submodule update --init
git pull origin main
git checkout main

export Grpc__Endpoint="http://35.88.68.211:31089"

cd Samples/GridServerLike/
dotnet publish --self-contained -r linux-x64 DataSynapseLike.sln

scp -i ~/.ssh/cluster-key packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip ec2-user@34.219.162.18:/data

cd ArmoniK.Samples.GridServer.Client/
dotnet bin/net5.0/linux-x64/ArmoniK.Samples.GridServer.Client.dll
