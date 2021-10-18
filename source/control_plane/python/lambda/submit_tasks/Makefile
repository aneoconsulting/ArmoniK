# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

SUBMIT_TASKS_IMAGE=submit_tasks
CONTEXT_DIR=../../../../..
SRCS=submit_tasks.py
export ARMONIK_TAG
DOCKER_REGISTRY=

.PHONY: all lambda-submit-tasks build-lambda-submit-tasks push-lambda-submit-tasks

all: lambda-submit-tasks
lambda-submit-tasks: build-lambda-submit-tasks push-lambda-submit-tasks

build-lambda-submit-tasks: Dockerfile
ifneq ($(DOCKER_REGISTRY),)
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(SUBMIT_TASKS_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
else
	docker build $(CONTEXT_DIR) -t $(SUBMIT_TASKS_IMAGE):$(ARMONIK_TAG) -f ./Dockerfile
endif

push-lambda-submit-tasks: build-lambda-submit-tasks
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(SUBMIT_TASKS_IMAGE):$(ARMONIK_TAG)
endif

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)