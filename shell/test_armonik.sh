#!/bin/bash

export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort

cd $HOME/ArmoniK/
if [ -d source/ArmoniK.Extensions.Csharp ] 
then
    git submodule update --init --recursive
else
    git clone https://github.com/aneoconsulting/ArmoniK.Extensions.Csharp.git source/ArmoniK.Extensions.Csharp
fi

bash ./tools/tests/symphony_like.sh
bash ./tools/tests/datasynapse_like.sh
bash ./tools/tests/symphony_endToendTests.sh
