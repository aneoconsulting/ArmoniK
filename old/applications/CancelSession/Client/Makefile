# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

SUBMITTER_IMAGE_NAME=cancel_session
BUILD_TYPE?=Release
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY

.PHONY: push push
all: push

.PHONY: all clean

all: push

build: Dockerfile Dockerfile_Debug
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build ../../../ -t $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile_Debug
else
	docker build ../../../ -t $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build ../../../ -t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile_Debug
else
	docker build ../../../ -t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif
endif

push: build
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG)
endif

