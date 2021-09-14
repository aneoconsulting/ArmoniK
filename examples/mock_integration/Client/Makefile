# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

GENERATED?=$(shell pwd)/generated/dotnet5.0/client
DIST_DIR?=$(shell pwd)/../../../dist
SUBMITTER_IMAGE_NAME=submitter
TAG=main
ACCOUNT_ID?=$(shell aws sts get-caller-identity | jq -r '.Account')
REGION=eu-west-1
DOCKER_REGISTRY=
DOCKER_REGISTRY_WITH_SUFFIX=$(shell if [ "$(DOCKER_REGISTRY)" != "" ]; then echo "$(DOCKER_REGISTRY)/"; else echo ""; fi)
BUILD_TYPE?=Release

.PHONY: push push
all: push

.PHONY: all clean

all: push

build: Dockerfile Dockerfile_Debug
ifeq ($(BUILD_TYPE), Debug)
	docker build  ../../../ -t $(DOCKER_REGISTRY_WITH_SUFFIX)$(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile_Debug
else
	docker build  ../../../ -t $(DOCKER_REGISTRY_WITH_SUFFIX)$(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile
endif

push: build
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG)
endif

