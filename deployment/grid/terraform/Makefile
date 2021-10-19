# Copyright 2021-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file
# except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on an "AS IS"
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied. See the
# License for the specific language governing permissions and limitations under the License

export GRAFANA_ADMIN_PASSWORD?=$(shell uuidgen)
export ARMONIK_TAG
export ARMONIK_REGION?=eu-west-1
KMS_KEY_ARN:=$(shell aws cloudformation describe-stacks --stack-name $(ARMONIK_TAG) --region $(ARMONIK_REGION) --query 'Stacks[0].Outputs[4].OutputValue' --output text)
S3_GRID_TFSTATE_BUCKET_NAME:=$(shell aws cloudformation describe-stacks --stack-name $(ARMONIK_TAG) --region $(ARMONIK_REGION) --query 'Stacks[0].Outputs[3].OutputValue' --output text)
TF_SRCS:=$(wildcard *.tf)

all:

.PHONY: clean apply reset init

#$(BUILD_DIR)/grid:
#	mkdir -p $@
	
init:
	terraform init

apply: $(TF_SRCS) $(GRID_CONFIG)
	terraform apply -var-file $(GRID_CONFIG) -var kms_key_arn=$(KMS_KEY_ARN)  -var="grafana_admin_password=$(GRAFANA_ADMIN_PASSWORD)"

destroy:
	terraform destroy -var-file $(GRID_CONFIG) -var kms_key_arn=$(KMS_KEY_ARN)

get-grafana-password:
	@terraform output grafana_admin_password

reset:
	rm -rf .terraform
	
clean:
	rm -rf $(BUILD_DIR)/tag.*
	