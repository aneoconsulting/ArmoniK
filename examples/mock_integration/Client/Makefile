# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

GENERATED?=$(shell pwd)/generated/dotnet5.0/client
DIST_DIR?=$(shell pwd)/../../../dist
SUBMITTER_IMAGE_NAME=submitter
TAG=main
DOCKER_REGISTRY=
BUILD_TYPE?=Release

export HTTP_PROXY
export HTTPS_PROXY
export http_proxy
export https_proxy
#export proxy

PROXY=$(shell if [ "$(HTTP_PROXY)" != "" ]; then echo "$(HTTP_PROXY)"; elif [ "$(HTTPS_PROXY)" != "" ]; then echo "$(HTTPS_PROXY)"; elif [ "$(http_proxy)" != "" ]; then echo "$(http_proxy)"; elif [ "$(https_proxy)" != "" ]; then echo "$(https_proxy)"; fi)
#PROXY=$(proxy)
PROTOCOL=$(shell echo "$(PROXY)" | cut -d ":" -f1)
ENDPOINT=$(shell echo "$(PROXY)" | cut -d "@" -f2)
TMP=$(shell echo "$(PROXY)" | cut -d "@" -f1)
USER=$(shell echo $(TMP) | grep -o -P '(?<=http://).*(?=\:)')
PASSWORD=$(shell echo "$(TMP)" | cut -d: -f3)
ENDPOINT_URL="$(PROTOCOL)://$(ENDPOINT)"

.PHONY: push push
all: push

.PHONY: all clean

all: add-nuget-config build push

add-nuget-config: nuget.config.tpl
	cat nuget.config.tpl | sed "s%{{endpoint_url}}%$(ENDPOINT_URL)%;s%{{user}}%$(USER)%;s%{{password}}%$(PASSWORD)%" > NuGet.Config

build: add-nuget-config Dockerfile Dockerfile_Debug
ifneq ($(DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build ../../../ -t $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile_Debug
else
	docker build ../../../ -t $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build ../../../ -t $(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile_Debug
else
	docker build ../../../ -t $(SUBMITTER_IMAGE_NAME):$(TAG) -f ./Dockerfile
endif
endif

push: build
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(TAG)
endif

