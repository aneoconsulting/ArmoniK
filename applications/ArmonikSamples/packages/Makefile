# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG?=mainline

CURRENT_DIR:=$(shell pwd)

BUILD_TYPE?=Release
DIST_DIR?=$(shell pwd)/../../../dist
DOCKER_REGISTRY=

.PHONY: clean

all: build


build: Dockerfile import-dll
ifneq ($(DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build .. -f ./Dockerfile_Debug -t $(DOCKER_REGISTRY)/lambda:$(TAG) --progress=plain
else
	docker build .. -f ./Dockerfile -t $(DOCKER_REGISTRY)/lambda:$(TAG) --progress=plain
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build .. -f ./Dockerfile_Debug -t lambda:$(TAG) --progress=plain
else
	docker build .. -f ./Dockerfile -t lambda:$(TAG) --progress=plain
endif
endif

upload: build
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/lambda:$(TAG)
endif

import-dll:
	mkdir -p ./images/lib/
	mkdir -p ./images/dist
	cp -v ../lib/*.dll ./packages/images/lib/ || true
	cp -v ${ARMONIK_NUGET_REPOS}/*.nupkg ./images/dist/

ifeq ($(BUILD_TYPE), Debug)
	cp -v ${ARMONIK_NUGET_REPOS}/*.pdb ./images/dist/
	cp -v ../lib/*.pdb ./packages/images/lib/
endif

clean:
	rm -rf ./images/lib ./images/dist