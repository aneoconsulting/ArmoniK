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

all:

.PHONY: clean apply reset init

init:
	terraform init

apply: $(TF_SRCS) $(GRID_CONFIG)
	terraform apply -var-file $(GRID_CONFIG)

destroy:
	terraform destroy -var-file $(GRID_CONFIG)

validate:
	terraform validate

reset:
	rm -rf .terraform* terraform.tfstate* Agent_config.json
	
clean: reset
	