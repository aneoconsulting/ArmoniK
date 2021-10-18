# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

export ARMONIK_TAG
REGION?=eu-west-1
KMS_KEY_ARN:=$(shell aws cloudformation describe-stacks --stack-name $(ARMONIK_TAG) --region $(REGION) --query 'Stacks[0].Outputs[4].OutputValue' --output text)
S3_IMAGE_TFSTATE_BUCKET_NAME:=$(shell aws cloudformation describe-stacks --stack-name $(ARMONIK_TAG) --region $(REGION) --query 'Stacks[0].Outputs[1].OutputValue' --output text)
TF_SRCS:=$(wildcard *.tf)

all:

.PHONY: clean apply destroy reset

	
init:
	terraform init -backend-config="bucket=$(S3_IMAGE_TFSTATE_BUCKET_NAME)" -backend-config="region=$(REGION)"

apply: $(TF_SRCS) $(GRID_CONFIG)
	terraform apply -var-file ./images_config.json -var kms_key_arn=$(KMS_KEY_ARN) -parallelism=1

destroy:
	terraform destroy -var-file ./images_config.json -var kms_key_arn=$(KMS_KEY_ARN)

reset:
	rm -rf .terraform
	
clean:
	rm -rf $(BUILD_DIR)/tag.*
	