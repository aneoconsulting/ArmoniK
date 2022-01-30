#!/bin/bash

cd ../../source/ArmoniK.Samples

export Grpc__Endpoint="http://ac184b105a6a34d4893dc2b3f84764d9-1993792179.eu-west-3.elb.amazonaws.com:5001"

cd Samples/GridServerLike/
dotnet publish --self-contained -r linux-x64 DataSynapseLike.sln

#scp -i ~/.ssh/cluster-key packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip ec2-user@54.213.147.130:/data
aws s3 cp packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip s3://s3fs-40lrt

cd ArmoniK.Samples.GridServer.Client/
dotnet bin/net5.0/linux-x64/ArmoniK.Samples.GridServer.Client.dll
