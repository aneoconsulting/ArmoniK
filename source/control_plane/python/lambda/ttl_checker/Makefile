# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

DOCKER_REGISTRY=
TTL_CHECKER_IMAGE=ttl_checker
CONTEXT_DIR=../../../../..
SRCS=ttl_checker.py
export ARMONIK_TAG

.PHONY: all lambda-ttl-checker build-lambda-ttl-checker push-lambda-ttl-checker

all: lambda-ttl-checker
lambda-ttl-checker: build-lambda-ttl-checker push-lambda-ttl-checker

build-lambda-ttl-checker: Dockerfile
ifneq ($(DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(TTL_CHECKER_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
else
	docker build $(CONTEXT_DIR) -t $(TTL_CHECKER_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
endif

push-lambda-ttl-checker: build-lambda-ttl-checker
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(TTL_CHECKER_IMAGE):$(ARMONIK_TAG)
endif

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)