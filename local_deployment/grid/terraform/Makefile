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

TF_SRCS:=$(wildcard *.tf)
REDIS_CERTIFICATES_DIRECTORY=
DOCKER_REGISTRY=

all:

.PHONY: clean apply reset init

#$(BUILD_DIR)/grid:
#	mkdir -p $@
	
init:
	terraform init

apply: $(TF_SRCS) $(GRID_CONFIG)
	terraform apply -var-file $(GRID_CONFIG) -var="certificates_dir_path=$(REDIS_CERTIFICATES_DIRECTORY)" -var="docker_registry=$(DOCKER_REGISTRY)"

destroy:
	terraform destroy -var-file $(GRID_CONFIG) -var="certificates_dir_path=$(REDIS_CERTIFICATES_DIRECTORY)" -var="docker_registry=$(DOCKER_REGISTRY)"

validate:
	terraform validate

reset:
	rm -rf .terraform
	
clean:
	rm -rf $(BUILD_DIR)/tag.*
	