# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

LAMBDA_AGENT_IMAGE_NAME=awshpc-lambda
LOCAL_AGENT_IMAGE_NAME=awshpc-local
CONTEXT_DIR=../../../..
SRCS=agent.py
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY


.PHONY: all lambda local push-lambda build-lambda build-local push-local

all: lambda
lambda: build-lambda push-lambda
local: build-local push-local

build-lambda: Dockerfile.Lambda
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(ARMONIK_DOCKER_REGISTRY)/$(LAMBDA_AGENT_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile.Lambda
else
	docker build $(CONTEXT_DIR) -t $(LAMBDA_AGENT_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile.Lambda
endif

push-lambda: build-lambda
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/$(LAMBDA_AGENT_IMAGE_NAME):$(ARMONIK_TAG)
endif

build-local: Dockerfile.Local
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(ARMONIK_DOCKER_REGISTRY)/$(LOCAL_AGENT_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile.Local
else
	docker build $(CONTEXT_DIR) -t $(LOCAL_AGENT_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile.Local
endif

push-local: build-local
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/$(LOCAL_AGENT_IMAGE_NAME):$(ARMONIK_TAG)
endif

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)