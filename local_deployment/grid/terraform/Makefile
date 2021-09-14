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

REGION?=eu-west-1

HTCGRID_ACCOUNT_ID:=$(shell aws sts get-caller-identity --query 'Account' --output text)
export GRAFANA_ADMIN_PASSWORD?=$(shell uuidgen)
TF_SRCS:=$(wildcard *.tf)
REDIS_CERTIFICATES_DIRECTORY=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

all:

.PHONY: clean apply reset init

#$(BUILD_DIR)/grid:
#	mkdir -p $@
	
init:
	terraform init

apply: $(TF_SRCS) $(GRID_CONFIG)
	terraform apply -var-file $(GRID_CONFIG) -var="certificates_dir_path=$(REDIS_CERTIFICATES_DIRECTORY)" -var="grafana_admin_password=$(GRAFANA_ADMIN_PASSWORD)"

destroy:
	terraform destroy -var-file $(GRID_CONFIG) -var="certificates_dir_path=$(REDIS_CERTIFICATES_DIRECTORY)"

get-grafana-password:
	@terraform output grafana_admin_password

reset:
	rm -rf .terraform
	
clean:
	rm -rf $(BUILD_DIR)/tag.*
	