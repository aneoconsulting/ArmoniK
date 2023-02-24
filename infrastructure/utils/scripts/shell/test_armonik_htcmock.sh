#!/bin/bash
export CONTROL_PLANE_URL=$(cat ~/ArmoniK/infrastructure/quick-deploy/localhost/all/generated/armonik-output.json | jq -r '.armonik.control_plane_url')
export core_version=`jq .'armonik_versions.core' ~/ArmoniK/versions.tfvars.json`
export core_version=${core_version:1:(-1)}
docker run --rm \
            -e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
            -e HtcMock__NTasks=5000 \
            -e HtcMock__TotalCalculationTime=00:00:00.100 \
            -e HtcMock__DataSize=1 \
            -e HtcMock__MemorySize=1 \
            -e HtcMock__SubTasksLevels=1 \
            -e HtcMock__EnableUseLowMem=true \
            -e HtcMock__EnableSmallOutput=true \
            -e HtcMock__EnableFastCompute=true \
            -e HtcMock__Partition="htcmock" \
            dockerhubaneo/armonik_core_htcmock_test_client:$core_version