#!/bin/bash

cd ../../source/ArmoniK.Samples

export Grpc__Endpoint="http://a065ae9d696194eb8997256dff5d339a-440286424.eu-west-3.elb.amazonaws.com:5001"

cd Samples/SymphonyLike/
dotnet publish --self-contained -r linux-x64 SymphonyLike.sln

#scp -i ~/.ssh/cluster-key packages/ArmoniK.Samples.SymphonyPackage-v1.0.0.zip ec2-user@54.213.147.130:/data
aws s3 cp packages/ArmoniK.Samples.SymphonyPackage-v1.0.0.zip s3://s3fs-51uxy

cd ArmoniK.Samples.SymphonyClient/
dotnet bin/Debug/net5.0/linux-x64/ArmoniK.Samples.SymphonyClient.dll
