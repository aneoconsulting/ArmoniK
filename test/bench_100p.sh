#!/bin/bash

#ArmoniK "2.11.0"
export CONTROL_PLANE_URL=http://a66eb16a0fa7c47e2ba73f0a069a4692-1254953721.eu-west-3.elb.amazonaws.com:5001/

#nb_pods=100

#run  1000 tasks 100ms
docker run --rm \
	-e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
	-e BenchOptions__nTasks=1000 \
	-e BenchOptions__TaskDurationMs=1000 \
	-e BenchOptions__PaloadSize=1 \
	-e BenchOptions__ResultSize=1 \
	-e BenchOptions__Partition=default \
    -e BenchOptions__ShowEvents=true \
	-e BenchOptions__BatchSize=10 \
	dockerhubaneo/armonik_core_bench_test_client:0.11.2-jgfixbench.8.be5c1433
