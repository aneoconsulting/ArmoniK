# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

SUBMITTER_IMAGE_NAME=submitter
TAG=mainline
ACCOUNT_ID?=$(shell aws sts get-caller-identity | jq -r '.Account')
REGION=eu-west-1
DOCKER_REGISTRY=$(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com

.PHONY: push push 
all: push 

build: Dockerfile
	docker build  -t $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile

push: build
	docker push $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG)

