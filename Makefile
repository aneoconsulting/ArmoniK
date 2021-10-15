# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

export LAMBDA_AGENT_IMAGE_NAME=awshpc-lambda
export SUBMITTER_IMAGE_NAME=submitter
export GENERATED=$(shell pwd)/generated
export DIST_DIR=$(shell pwd)/dist
export FILE_HANDLER
BUILD_TYPE?=Release
PACKAGE_DIR:=./dist
PACKAGES:= $(wildcard $(PACKAGE_DIR)/*.whl)

.PHONY: all utils api lambda submitter packages test test-api test-utils test-agent lambda-control-plane

all: utils api lambda lambda-control-plane

###############################################
#######     Manage HTC grid states     ########
###############################################

init-grid-state:
	$(MAKE) -C ./deployment/init_grid/cloudformation init
	$(MAKE) -C ./deployment/init_grid/cloudformation

delete-grid-state:
	$(MAKE) -C ./deployment/init_grid/cloudformation delete


#############################################################################
#### Manage images transfer from third parties to given docker registry  ####
#############################################################################
init-images:
	@$(MAKE) -C ./deployment/image_repository/terraform init

reset-images-deployment:
	@$(MAKE) -C ./deployment/image_repository/terraform reset

transfer-images:
	@$(MAKE) -C ./deployment/image_repository/terraform apply

destroy-images:
	@$(MAKE) -C ./deployment/image_repository/terraform destroy



###############################################
#### Manage HTC grid terraform deployment  ####
###############################################
init-grid-deployment:
	@$(MAKE) -C ./deployment/grid/terraform init

reset-grid-deployment:
	@$(MAKE) -C ./deployment/grid/terraform reset

apply-dotnet-runtime:
	@$(MAKE) -C ./deployment/grid/terraform apply GRID_CONFIG=$(GENERATED)/dotnet5.0_runtime_grid_config.json

destroy-dotnet-runtime:
	@$(MAKE) -C ./deployment/grid/terraform destroy GRID_CONFIG=$(GENERATED)/dotnet5.0_runtime_grid_config.json

apply-custom-runtime:
	@$(MAKE) -C ./deployment/grid/terraform apply GRID_CONFIG=$(GENERATED)/grid_config.json

destroy-custom-runtime:
	@$(MAKE) -C ./deployment/grid/terraform destroy GRID_CONFIG=$(GENERATED)/grid_config.json

show-password:
	@$(MAKE) -C ./deployment/grid/terraform get-grafana-password

clean-grid-local-project: clean-grid-local-deployment
	rm -rf $(GENERATED) $(DIST_DIR)

init-grid-local-deployment:
	@$(MAKE) -C ./local_deployment/grid/terraform init

reset-grid-local-deployment:
	@$(MAKE) -C ./local_deployment/grid/terraform reset

apply-dotnet-local-runtime:
	@$(MAKE) -C ./local_deployment/grid/terraform apply GRID_CONFIG=$(GENERATED)/local_dotnet5.0_runtime_grid_config.json

destroy-dotnet-local-runtime:
	@$(MAKE) -C ./local_deployment/grid/terraform destroy GRID_CONFIG=$(GENERATED)/local_dotnet5.0_runtime_grid_config.json

clean-grid-local-deployment:
	@$(MAKE) -C ./local_deployment/grid/terraform clean

#############################
##### building source #######
#############################
http-apis:
	$(MAKE) -C ./source/control_plane/openapi/ all BUILD_TYPE=$(BUILD_TYPE)

utils:
	$(MAKE) -C ./source/client/python/utils

install-utils: utils
	pip install --force-reinstall $(PACKAGE_DIR)/utils-*.whl

test-utils:
	$(MAKE) test -C ./source/client/python/utils

api: http-apis
	$(MAKE) -C ./source/client/python/api-v0.1

dotnet5.0-htcgrid-api: http-apis
	$(MAKE) -C ./source/client/csharp/api-v0.1 BUILD_TYPE=$(BUILD_TYPE)

test-api: install-utils
	$(MAKE) test -C ./source/client/python/api-v0.1

test-agent:
	$(MAKE) test -C ./source/compute_plane/python/agent

packages: api utils

test-packages: test-api test-utils

test: test-agent test-packages

#############################
##### building images #######
#############################
lambda: utils api
	$(MAKE) -C ./source/compute_plane/python/agent

dotnet-submitter: utils api
	$(MAKE) -C ./examples/client/csharp/
	
mock-submitter: utils api
	$(MAKE) -C ./examples/mock_integration/Client/ BUILD_TYPE=$(BUILD_TYPE)

cancel-session: utils api
	$(MAKE) -C ./examples/mock_integration/CancelSession/ BUILD_TYPE=$(BUILD_TYPE)

lambda-control-plane: utils api lambda-control-plane-submit-tasks lambda-control-plane-get-results lambda-control-plane-cancel-tasks lambda-control-plane-ttl-checker

lambda-control-plane-submit-tasks: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/submit_tasks

lambda-control-plane-get-results: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/get_results

lambda-control-plane-cancel-tasks: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/cancel_tasks

lambda-control-plane-ttl-checker: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/ttl_checker

####################################
##### building documentation #######
####################################
doc: import
	mkdocs build

serve: import
	mkdocs serve

import: packages $(PACKAGES)
	pip install --force-reinstall $(PACKAGES)

######################################
##### upload workload binaries #######
######################################

upload-dotnet5.0: mock-config-dotnet5.0 mock-config-local-dotnet5.0
	$(MAKE) -C ./examples/mock_integration upload BUILD_TYPE=$(BUILD_TYPE)


#############################
##### generate config #######
#############################

mock-config-dotnet5.0:
	@$(MAKE) -C ./examples/configurations generated-dotnet5.0 FILE_HANDLER="mock_integration::mock_integration.Function::FunctionHandler" BUILD_TYPE=$(BUILD_TYPE)

mock-config-local-dotnet5.0:
	@$(MAKE) -C ./examples/configurations generated-local-dotnet5.0 FILE_HANDLER="mock_integration::mock_integration.Function::FunctionHandler" BUILD_TYPE=$(BUILD_TYPE)

###############################
##### generate k8s jobs #######
###############################
k8s-jobs:
	@$(MAKE) -C ./examples/submissions/k8s_jobs


#############################
##### path per example ######
#############################

dotnet50-path: all dotnet5.0-htcgrid-api upload-dotnet5.0 mock-submitter cancel-session mock-config-dotnet5.0 mock-config-local-dotnet5.0 k8s-jobs

#############################
##### C#              #######
#############################
# Place client code at the same level as root of project.
# make build-dotnet5.0 BUILD_TYPE=Debug
build-dotnet5.0: build-dotnet5.0-api build-htc-grid-dotnet5.0-api build-dotnet5.0-mock-integration upload-dotnet5.0

build-dotnet5.0-api:
	cd ./generated/csharp/http_api/ && dotnet restore src/HttpApi/ && dotnet build src/HttpApi/ --configuration $(BUILD_TYPE)
	mkdir -p ./examples/client/csharp/lib
	cp ./generated/csharp/http_api/src/HttpApi/bin/$(BUILD_TYPE)/net5.0/HttpApi.dll ./examples/client/csharp/lib/
	cp ./generated/csharp/http_api/src/HttpApi/bin/$(BUILD_TYPE)/net5.0/HttpApi.dll ./examples/mock_integration/lib

build-htc-grid-dotnet5.0-api:
	$(MAKE) -C ./source/client/csharp/api-v0.1 all BUILD_TYPE=$(BUILD_TYPE)
	mkdir -p ./examples/client/csharp/lib/
	cp ./source/client/csharp/api-v0.1/bin/$(BUILD_TYPE)/net5.0/HTCGridAPI.dll ./examples/client/csharp/lib/
	cp ./source/client/csharp/api-v0.1/bin/$(BUILD_TYPE)/net5.0/HTCGridAPI.dll ./examples/mock_integration/lib/

build-dotnet5.0-simple-client:
	$(MAKE) -C ./examples/client/csharp/ BUILD_TYPE=$(BUILD_TYPE)

build-dotnet5.0-mock-integration:
	$(MAKE) -C ./examples/mock_integration/ BUILD_TYPE=$(BUILD_TYPE)

