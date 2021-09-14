# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

LAMBDA_AGENT_IMAGE_NAME=awshpc-lambda
LOCAL_AGENT_IMAGE_NAME=awshpc-local
TAG=mainline
DOCKER_REGISTRY=
CONTEXT_DIR=../../../..
SRCS=agent.py

.PHONY: all lambda local push-lambda build-lambda build-local push-local

all: lambda
lambda: build-lambda push-lambda
local: build-local push-local

build-lambda: Dockerfile.Lambda
ifneq ($(DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(LAMBDA_AGENT_IMAGE_NAME):$(TAG) -f ./Dockerfile.Lambda
else
	docker build $(CONTEXT_DIR) -t $(LAMBDA_AGENT_IMAGE_NAME):$(TAG) -f ./Dockerfile.Lambda
endif

push-lambda: build-lambda
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(LAMBDA_AGENT_IMAGE_NAME):$(TAG)
endif

build-local: Dockerfile.Local
ifneq ($(DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(LOCAL_AGENT_IMAGE_NAME):$(TAG) -f ./Dockerfile.Local
else
	docker build $(CONTEXT_DIR) -t $(LOCAL_AGENT_IMAGE_NAME):$(TAG) -f ./Dockerfile.Local
endif

push-local: build-local
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(LOCAL_AGENT_IMAGE_NAME):$(TAG)
endif

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)