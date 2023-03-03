#!/bin/bash

#ArmoniK "2.11.0"
export CONTROL_PLANE_URL=http://a24fc0af6e62547d6b9b26d86873fd36-1938019023.eu-west-3.elb.amazonaws.com:5001/

#nb_pods=100

#run  10000 tasks on 100 pods
docker run --rm \
	-e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
	-e BenchOptions__nTasks=100 \
	-e BenchOptions__TaskDurationMs=10 \
	-e BenchOptions__PaloadSize=100 \
	-e BenchOptions__ResultSize=100 \
	-e BenchOptions__Partition=default \
    -e BenchOptions__ShowEvents=true \
	-e BenchOptions__BatchSize=100 \
	dockerhubaneo/armonik_core_bench_test_client:0.11.2-jgfixbench.8.be5c1433
