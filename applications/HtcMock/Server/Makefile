# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

BUILD_TYPE?=Release
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY

.PHONY: clean

build: Dockerfile import-dll
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build . -f ./Dockerfile_Debug -t $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG) --progress=plain
else
	docker build . -f ./Dockerfile -t $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG) --progress=plain
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build . -f ./Dockerfile_Debug -t lambda:$(ARMONIK_TAG) --progress=plain
else
	docker build . -f ./Dockerfile -t lambda:$(ARMONIK_TAG) --progress=plain
endif
endif


upload: build
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG)
endif

import-dll:
	mkdir -p ./mock_integration_image/src/mock_integration/lib/
	mkdir -p ./mock_integration_image/src/mock_integration/dist/
	cp -v $(ARMONIK_NUGET_REPOS)/*.nupkg ./mock_integration_image/src/mock_integration/dist/

clean:
	rm -rf ./mock_integration_image/src/mock_integration/lib
	rm -rf ./mock_integration_image/src/mock_integration/dist/