# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

GENERATED?=$(shell pwd)/generated/dotnet5.0/client
DIST_DIR?=$(shell pwd)/../../../dist
SUBMITTER_IMAGE_NAME=cancel_session
BUILD_TYPE?=Release
export ARMONIK_TAG
DOCKER_REGISTRY=


.PHONY: push push
all: push

.PHONY: all clean

all: push

build: Dockerfile Dockerfile_Debug
ifneq ($(DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build ../../../ -t $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile_Debug
else
	docker build ../../../ -t $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build ../../../ -t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile_Debug
else
	docker build ../../../ -t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif
endif

push: build
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG)
endif

