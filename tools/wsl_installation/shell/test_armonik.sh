#!/bin/bash
set -x
export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort

# cd $HOME/ArmoniK/
# if [ -d source/ArmoniK.Extensions.Csharp ] 
# then
#     git submodule update --init --recursive
# else
#     git clone https://github.com/aneoconsulting/ArmoniK.Extensions.Csharp.git source/ArmoniK.Extensions.Csharp
# fi

cd $HOME/ArmoniK/
if [ -d source/ArmoniK.Samples ] 
then
    git submodule update --init --recursive
else
    git clone https://github.com/aneoconsulting/ArmoniK.Samples.git
fi

bash ArmoniK.Samples/tools/tests/symphony_like.sh -e $Grpc__Endpoint pTask 1000
bash ArmoniK.Samples/tools/tests/unified_api.sh -e $Grpc__Endpoint pTask 1000