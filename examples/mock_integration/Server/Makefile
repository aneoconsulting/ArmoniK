# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG?=mainline

CURRENT_DIR:=$(shell pwd)

BUILD_TYPE?=Release
DIST_DIR?=$(shell pwd)/../../../dist
DOCKER_REGISTRY=$(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com

.PHONY: clean


build: Dockerfile import-dll
	docker build . -f ./Dockerfile -t $(DOCKER_REGISTRY)/lambda:$(TAG)

upload: build
	docker push $(DOCKER_REGISTRY)/lambda:$(TAG)

import-dll:
	mkdir -p ./mock_integration_image/src/mock_integration/lib/
	mkdir -p ./mock_integration_image/src/mock_integration/dist/dotnet5.0
	cp -v ../lib/*.dll ./mock_integration_image/src/mock_integration/lib/

	cp -v $(DIST_DIR)/dotnet5.0/*.nupkg ./mock_integration_image/src/mock_integration/dist/dotnet5.0

clean:
	rm lambda.zip
	rm -rf ./mock_integration_image/src/mock_integration/lib