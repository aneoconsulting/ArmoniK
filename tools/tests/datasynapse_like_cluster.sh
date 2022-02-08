#!/bin/bash

cd ../../source/ArmoniK.Samples

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].hostname" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
export S3_BUCKET=$(aws s3api list-buckets | jq -r '.Buckets[0].Name')

cd Samples/GridServerLike/
dotnet publish --self-contained -r linux-x64 DataSynapseLike.sln

#scp -i ~/.ssh/cluster-key packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip ec2-user@54.213.147.130:/data
#aws s3 sync --exclude "*" --include packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip . s3://$S3_BUCKET
aws s3 cp packages/ArmoniK.Samples.GridServer.Client-v1.0.0.zip s3://$S3_BUCKET
kubectl delete -n armonik $(kubectl get pods -n armonik -l service=compute-plane --no-headers=true -o name)


cd ArmoniK.Samples.GridServer.Client/
dotnet bin/net5.0/linux-x64/ArmoniK.Samples.GridServer.Client.dll
