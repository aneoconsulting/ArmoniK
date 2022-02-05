#!/bin/bash

cd ../../source/ArmoniK.Samples

export Grpc__Endpoint="http://a2b1b0cd23aa94f24860bab070cc5dcc-141123780.eu-west-3.elb.amazonaws.com:5001"
cd Samples/SymphonyLike/
dotnet publish --self-contained -r linux-x64 SymphonyLike.sln

#scp -i ~/.ssh/cluster-key packages/ArmoniK.Samples.SymphonyPackage-v1.0.0.zip ec2-user@54.213.147.130:/data
aws s3 cp packages/ArmoniK.Samples.SymphonyPackage-v1.0.0.zip s3://armonik-s3fs-ai05v

cd ArmoniK.Samples.SymphonyClient/
dotnet bin/Debug/net5.0/linux-x64/ArmoniK.Samples.SymphonyClient.dll
