#!/bin/bash
set -e

cd ../../source/ArmoniK.Samples

export CPIP=$(kubectl get svc ingress -n armonik -o custom-columns="IP:.status.loadBalancer.ingress[*].hostname" --no-headers=true)
export CPPort=$(kubectl get svc ingress -n armonik -o custom-columns="PORT:.spec.ports[1].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
export S3_BUCKET=$(aws s3api list-buckets --output json | jq -r '.Buckets[0].Name')

cd Samples/SymphonyLike/
dotnet publish --self-contained -r linux-x64 SymphonyLike.sln

#scp -i ~/.ssh/cluster-key packages/ArmoniK.Samples.SymphonyPackage-v2.0.0.zip ec2-user@54.213.147.130:/data
#aws s3 sync --exclude "*" --include ArmoniK.Samples.SymphonyPackage-v2.0.0.zip packages/ s3://$S3_BUCKET

aws s3 cp packages/ArmoniK.Samples.SymphonyPackage-v2.0.0.zip s3://$S3_BUCKET
kubectl delete -n armonik $(kubectl get pods -n armonik -l service=compute-plane --no-headers=true -o name) || true

cd ArmoniK.Samples.SymphonyClient/
dotnet bin/Debug/net5.0/linux-x64/ArmoniK.Samples.SymphonyClient.dll
