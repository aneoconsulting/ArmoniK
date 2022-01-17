#!/bin/bash
TAGVar=0.0.6

cd ../../source/ArmoniK.Samples/Samples/HtcMock
docker build -t dockerhubaneo/armonik_worker_htcmock:$TAGVar -f GridWorker/src/Dockerfile .