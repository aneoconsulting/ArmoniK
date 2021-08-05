# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG?=mainline
BUCKET_NAME=$(shell aws cloudformation describe-stacks --stack-name $(TAG) --region $(REGION) --query 'Stacks[0].Outputs[0].OutputValue' --output text)

CURRENT_DIR:=$(shell pwd)

.PHONY: clean

build-env: 
	docker build ../../../.. -f ./Dockerfile -t builded-env:$(TAG)

build: build-env
	docker run --rm -v  $(CURRENT_DIR):/app  builded-env:$(TAG)

upload: build
	aws s3 cp lambda.zip s3://$(BUCKET_NAME)

clean:
	rm lambda.zip