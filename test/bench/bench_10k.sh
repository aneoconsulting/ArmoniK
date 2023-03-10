#!/bin/bash

#ArmoniK "2.11.0"
export CONTROL_PLANE_URL=http://ad806ebb1bc00400abb24329f929bdb6-1498426612.eu-west-3.elb.amazonaws.com:5001/

#nb_pods=100

#run  10000 tasks on 100 pods
docker run --rm \
	-e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
	-e BenchOptions__nTasks=10000 \
	-e BenchOptions__TaskDurationMs=500 \
	-e BenchOptions__PayloadSize=100 \
	-e BenchOptions__ResultSize=100 \
	-e BenchOptions__Partition=default \
    -e BenchOptions__ShowEvents=true \
	-e BenchOptions__BatchSize=1000 \
	dockerhubaneo/armonik_core_bench_test_client:0.11.2-jgfixbench.8.be5c1433
