# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

GENERATED?=$(shell pwd)/generated/dotnet5.0/client
DIST_DIR?=./dist
SUBMITTER_IMAGE_NAME=submitter
TAG=main
DOCKER_REGISTRY=
BUILD_TYPE?=Release
HTCGRID_PACKAGE=HTCGridAPI.1.0.0.nupkg
HTTPAPI_PACKAGE=HttpApi.1.0.0.nupkg
ARMONIKAPI_PACKAGE=Armonik.api.1.0.0.nupkg

.PHONY: push

all: push

.PHONY: all clean external_packages

all: push

external_packages:
	mkdir -p ../dist
	cp -u ${ARMONIK_NUGET_REPOS}/*.nupkg ../dist

build: external_packages Dockerfile Dockerfile_Debug
ifneq ($(DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile_Debug
else
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile_Debug
else
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile
endif
endif

push: build
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG)
endif

clean:
	rm -rf ../dist 2>&1 > /dev/null || true