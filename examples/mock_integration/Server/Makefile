# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG?=mainline
BUCKET_NAME=$(shell aws cloudformation describe-stacks --stack-name $(TAG) --region $(REGION) --query 'Stacks[0].Outputs[0].OutputValue' --output text)

CURRENT_DIR:=$(shell pwd)

BUILD_TYPE?=Release
DIST_DIR?=$(shell pwd)/../../../dist

.PHONY: clean



build-env: import-dll
	docker build . -f ./Dockerfile -t builded-env:$(TAG)

build: build-env
	docker run --rm -v  $(CURRENT_DIR):/app  builded-env:$(TAG)

upload: build
	aws s3 cp lambda.zip s3://$(BUCKET_NAME)

import-dll:
	mkdir -p ./mock_integration_image/src/mock_integration/lib/
	mkdir -p ./mock_integration_image/src/mock_integration/dist/dotnet5.0
	cp -v ../lib/*.dll ./mock_integration_image/src/mock_integration/lib/

	cp -v $(DIST_DIR)/dotnet5.0/*.nupkg ./mock_integration_image/src/mock_integration/dist/dotnet5.0

clean:
	rm lambda.zip
	rm -rf ./mock_integration_image/src/mock_integration/lib