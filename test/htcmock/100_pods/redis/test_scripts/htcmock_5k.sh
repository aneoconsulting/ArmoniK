#!/bin/bash

export CONTROL_PLANE_URL=$(cat ../../../../../infrastructure/quick-deploy/aws/armonik/generated/armonik-output.json | jq -r '.armonik.control_plane_url')

 docker run --rm \
              -e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
              -e HtcMock__NTasks=5000 \
              -e HtcMock__TotalCalculationTime=01:00:00.00 \
              -e HtcMock__DataSize=1 \
              -e HtcMock__MemorySize=1 \
              -e HtcMock__SubTasksLevels=4 \
              -e HtcMock__EnableUseLowMem=true \
              -e HtcMock__EnableSmallOutput=true \
              -e HtcMock__EnableFastCompute=true \
              -e HtcMock__Partition="htcmock" \
              dockerhubaneo/armonik_core_htcmock_test_client:0.13.1