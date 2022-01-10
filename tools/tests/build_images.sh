#!/bin/bash
TAGVar=0.0.6

cd ../../source/ArmoniK.Samples
git submodule update --init
git pull origin main
git checkout main

cd Samples/HtcMock
docker build -t dockerhubaneo/armonik_worker_htcmock:$TAGVar -f GridWorker/src/Dockerfile .
cd ../..