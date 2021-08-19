# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG?=mainline
ACCOUNT_ID?=$(shell aws sts get-caller-identity | jq -r '.Account')
REGION=eu-west-1
DOCKER_REGISTRY=$(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
CANCEL_TASKS_IMAGE=cancel_tasks
CONTEXT_DIR=../../../../..
SRCS=cancel_tasks.py

.PHONY: all lambda-cancel-tasks build-lambda-cancel-tasks push-lambda-cancel-tasks

all: lambda-cancel-tasks
lambda-cancel-tasks: build-lambda-cancel-tasks push-lambda-cancel-tasks

build-lambda-cancel-tasks: Dockerfile
	docker build $(CONTEXT_DIR) -t $(DOCKER_REGISTRY)/$(CANCEL_TASKS_IMAGE):$(TAG) -f ./Dockerfile

push-lambda-cancel-tasks: build-lambda-cancel-tasks
	docker push $(DOCKER_REGISTRY)/$(CANCEL_TASKS_IMAGE):$(TAG)

test: $(SRCS)
	flake8  --ignore  E501,W503 --statistic --exclude build $(SRCS)