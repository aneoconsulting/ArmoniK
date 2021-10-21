# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

GENERATED?=$(shell pwd)/generated/dotnet5.0/client
DIST_DIR?=$(shell pwd)/../../../dist
SUBMITTER_IMAGE_NAME=submitter
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY

.PHONY: push push
all: push

.PHONY: all clean

all: push

add-apis: $(DIST_DIR)/dotnet5.0/HttpApi.1.0.0.nupkg
	dotnet add package -s $(DIST_DIR)/dotnet5.0/  HttpApi

add-htc-grid-api: $(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg
	dotnet add package -s $(DIST_DIR)/dotnet5.0/  HTCGridAPI

bin/Release/net5.0/ref/SimpleClient.dll: add-apis add-htc-grid-api
	dotnet clean && dotnet build "SimpleClient.csproj" --configuration Release --output $(GENERATED)

build-dotnet: bin/Release/net5.0/ref/SimpleClient.dll

clean:
	dotnet clean
	rm -rf ./obj ./bin

build: Dockerfile
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker build ../../../ -t $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
else
	docker build ../../../ -t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif

push: build
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG)
endif
