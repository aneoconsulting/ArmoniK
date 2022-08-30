#!/bin/bash

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort

cd $HOME/ArmoniK/
if [ -d source/ArmoniK.Samples ] 
then
    git submodule update --init --recursive
else
    git clone https://github.com/aneoconsulting/ArmoniK.Samples.git
fi

cd ArmoniK.Samples
git checkout -b arm_install $1

bash tools/tests/gridserver_like.sh -e $Grpc__Endpoint pTask 1000
bash tools/tests/symphony_like.sh -e $Grpc__Endpoint pTask 1000
bash tools/tests/unified_api.sh -e $Grpc__Endpoint pTask 1000