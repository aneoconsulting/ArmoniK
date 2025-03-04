#!/usr/bin/env bash
set -euo pipefail

tasksPerJob=625000 
# 16 sessions * 62500 tasks = 1,000,000 tasks
# 16 sessions * 187500 tasks = 3,000,000 tasks
# 16 sessions * 312500 tasks = 5,000,000 tasks
# 16 sessions * 437500 tasks = 7,000,000 tasks
# 16 sessions * 625000 tasks = 10,000,000 tasks

batchSize=16
CORE_VERSION=0.29.1
TEMPLATE_FILE="tools/ci/bench-job-template.yml"

  for i in $(seq 1 ${batchSize}); do
    sessionName="bench-session-${i}"
    sed -e "s/@@ARMONIK_CORE_VERSION@@/${CORE_VERSION}/g" \
        -e "s/@@NTASKS@@/${tasksPerJob}/g" \
        -e "s/@@SESSION_NAME@@/${sessionName}/g" \
        "${TEMPLATE_FILE}" | kubectl apply -f -
    

  done

