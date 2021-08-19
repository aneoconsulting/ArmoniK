# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG?=mainline
ACCOUNT_ID?=$(shell aws sts get-caller-identity | jq -r '.Account')
REGION=eu-west-1
DOCKER_REGISTRY=$(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
GET_RESULTS_IMAGE=get_results
CONTEXT_DIR=../../../../..
SRCS=get_results.py

.PHONY: all lambda-get-results build-lambda-get-results push-lambda-get-results

all: lambda-get-results
lambda-get-results: build-lambda-get-results push-lambda-get-results

build-lambda-get-results: Dockerfile
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(GET_RESULTS_IMAGE):$(TAG) -f ./Dockerfile

push-lambda-get-results: build-lambda-get-results
	docker push $(DOCKER_REGISTRY)/$(GET_RESULTS_IMAGE):$(TAG)

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)