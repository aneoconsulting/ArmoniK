#!/bin/bash

#ArmoniK "2.11.0"
export CONTROL_PLANE_URL=http://a7507fe39bd80428e90d474478b13353-418506214.eu-west-3.elb.amazonaws.com:5001/

#run  10000 tasks on 100 pods
docker run --rm \
	-e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
	-e BenchOptions__nTasks=10000 \
	-e BenchOptions__TaskDurationMs=500 \
	-e BenchOptions__PayloadSize=100 \
	-e BenchOptions__ResultSize=100 \
	-e BenchOptions__Partition=bench \
    -e BenchOptions__ShowEvents=false \
	-e BenchOptions__BatchSize=50 \
	-e BenchOptions__MaxRetries=5 \
	-e BenchOptions__DegreeOfParallelism=10 \
	dockerhubaneo/armonik_core_bench_test_client:0.11.4-jgbench.13.e5bd3b7c
