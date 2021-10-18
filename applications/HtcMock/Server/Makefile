# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG?=mainline

CURRENT_DIR:=$(shell pwd)

BUILD_TYPE?=Release
DOCKER_REGISTRY=

.PHONY: clean


build: Dockerfile import-dll
ifneq ($(DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build . -f ./Dockerfile_Debug -t $(DOCKER_REGISTRY)/lambda:$(TAG) --progress=plain
else
	docker build . -f ./Dockerfile -t $(DOCKER_REGISTRY)/lambda:$(TAG) --progress=plain
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build . -f ./Dockerfile_Debug -t lambda:$(TAG) --progress=plain
else
	docker build . -f ./Dockerfile -t lambda:$(TAG) --progress=plain
endif
endif


upload: build
ifneq ($(DOCKER_REGISTRY),)
	docker push $(DOCKER_REGISTRY)/lambda:$(TAG)
endif

import-dll:
	mkdir -p ./mock_integration_image/src/mock_integration/lib/
	mkdir -p ./mock_integration_image/src/mock_integration/dist/
	cp -v $(ARMONIK_NUGET_REPOS)/*.nupkg ./mock_integration_image/src/mock_integration/dist/
ifeq ($(BUILD_TYPE), Debug)
	cp -v $(ARMONIK_NUGET_REPOS)/*.pdb ./mock_integration_image/src/mock_integration/dist/ || true
endif

clean:
	rm -rf ./mock_integration_image/src/mock_integration/lib
	rm -rf ./mock_integration_image/src/mock_integration/dist/