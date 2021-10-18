# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

CANCEL_TASKS_IMAGE=cancel_tasks
CONTEXT_DIR=../../../../..
SRCS=cancel_tasks.py
export ARMONIK_TAG
DOCKER_REGISTRY=

.PHONY: all lambda-cancel-tasks build-lambda-cancel-tasks push-lambda-cancel-tasks

all: lambda-cancel-tasks
lambda-cancel-tasks: build-lambda-cancel-tasks push-lambda-cancel-tasks

build-lambda-cancel-tasks: Dockerfile
ifneq ($(DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(CANCEL_TASKS_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
else
	docker build $(CONTEXT_DIR) -t $(CANCEL_TASKS_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
endif

push-lambda-cancel-tasks: build-lambda-cancel-tasks
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(CANCEL_TASKS_IMAGE):$(ARMONIK_TAG)
endif

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)