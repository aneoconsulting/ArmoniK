# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

LAMBDA_INIT_IMAGE_NAME=lambda-init
TAG=mainline
DOCKER_REGISTRY=
CONTEXT_DIR=.
LAMBDA_INIT_IMAGE_NAME=lambda-init

.PHONY: all lambda-init  push-lambda-init build-lambda-init

all: lambda-init
lambda-init: build-lambda-init push-lambda-init


build-lambda-init: Dockerfile
ifneq ($(DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(LAMBDA_INIT_IMAGE_NAME):$(TAG) -f ./Dockerfile
else
	docker build $(CONTEXT_DIR) -t $(LAMBDA_INIT_IMAGE_NAME):$(TAG) -f ./Dockerfile
endif

push-lambda-init: build-lambda-init
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(LAMBDA_INIT_IMAGE_NAME):$(TAG)
endif


