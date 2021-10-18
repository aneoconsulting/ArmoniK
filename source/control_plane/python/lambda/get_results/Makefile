# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

GET_RESULTS_IMAGE=get_results
CONTEXT_DIR=../../../../..
SRCS=get_results.py
export ARMONIK_TAG
DOCKER_REGISTRY=

.PHONY: all lambda-get-results build-lambda-get-results push-lambda-get-results

all: lambda-get-results
lambda-get-results: build-lambda-get-results push-lambda-get-results

build-lambda-get-results: Dockerfile
ifneq ($(DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(GET_RESULTS_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
else
	docker build $(CONTEXT_DIR) -t $(GET_RESULTS_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
endif

push-lambda-get-results: build-lambda-get-results
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(GET_RESULTS_IMAGE):$(ARMONIK_TAG)
endif

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)