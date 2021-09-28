# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

export TAG=mainline
export LAMBDA_AGENT_IMAGE_NAME=awshpc-lambda
export SUBMITTER_IMAGE_NAME=submitter
export GENERATED=$(shell pwd)/generated
export BUCKET_NAME
export FILE_HANDLER
export FUNCTION_HANDLER
export TABLE_SERVICE
export DIST_DIR=$(shell pwd)/dist
export GRAFANA_ADMIN_PASSWORD
export BUILD_DIR:=(shell pwd)/.build
export HTTP_PROXY
export HTTPS_PROXY
export NO_PROXY
export http_proxy
export https_proxy
export no_proxy

BUILD_TYPE?=Release

PACKAGE_DIR := ./dist
PACKAGES    := $(wildcard $(PACKAGE_DIR)/*.whl)
.PHONY: all utils api lambda submitter  packages test test-api test-utils test-agent lambda-control-plane config-c++

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

init-grid-local-deployment:
	@$(MAKE) -C ./local_deployment/grid/terraform k8s-config
	@$(MAKE) -C ./local_deployment/grid/terraform init

reset-grid-local-deployment:
	@$(MAKE) -C ./local_deployment/grid/terraform reset

apply-dotnet-local-runtime:
	@$(MAKE) -C ./local_deployment/grid/terraform apply GRID_CONFIG=$(GENERATED)/dotnet5.0_runtime_grid_config.json

destroy-dotnet-local-runtime:
	@$(MAKE) -C ./local_deployment/grid/terraform destroy GRID_CONFIG=$(GENERATED)/dotnet5.0_runtime_grid_config.json

apply-custom-local-runtime:
	@$(MAKE) -C ./local_deployment/grid/terraform apply GRID_CONFIG=$(GENERATED)/grid_config.json

destroy-custom-local-runtime:
	@$(MAKE) -C ./local_deployment/grid/terraform destroy GRID_CONFIG=$(GENERATED)/grid_config.json

show-local-password:
	@$(MAKE) -C ./local_deployment/grid/terraform get-grafana-password
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

python-submitter: utils api
	$(MAKE) -C ./examples/client/python

dotnet-submitter: utils api
	$(MAKE) -C ./examples/client/csharp/
	
mock-submitter: utils api
	$(MAKE) -C ./examples/mock_integration/Client/ BUILD_TYPE=$(BUILD_TYPE)

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
upload-c++: config-c++
	$(MAKE) -C ./examples/workloads/c++/mock_computation upload

upload-python: config-python
	$(MAKE) -C ./examples/workloads/python/mock_computation upload

upload-python-ql: config-python
	$(MAKE) -C ./examples/workloads/python/quant_lib upload

upload-dotnet5.0: mock-config-dotnet5.0
	$(MAKE) -C ./examples/mock_integration upload BUILD_TYPE=$(BUILD_TYPE)


#############################
##### generate config #######
#############################
config-c++:
	@$(MAKE) -C ./examples/configurations generated-c++

config-python:
	@$(MAKE) -C ./examples/configurations generated-python FILE_HANDLER=mock_compute_engine FUNCTION_HANDLER=lambda_handler

config-python-ql:
	@$(MAKE) -C ./examples/configurations generated-python FILE_HANDLER=portfolio_pricing_engine FUNCTION_HANDLER=lambda_handler

config-s3-c++:
	@$(MAKE) -C ./examples/configurations generated-s3-c++

config-dotnet5.0:
	@$(MAKE) -C ./examples/configurations generated-dotnet5.0 FILE_HANDLER="mock_subtasking::mock_subtasking.Function::FunctionHandler" BUILD_TYPE=$(BUILD_TYPE)
	
mock-config-dotnet5.0:
	@$(MAKE) -C ./examples/configurations generated-dotnet5.0 FILE_HANDLER="mock_integration::mock_integration.Function::FunctionHandler" BUILD_TYPE=$(BUILD_TYPE)
###############################
##### generate k8s jobs #######
###############################
k8s-jobs:
	@$(MAKE) -C ./examples/submissions/k8s_jobs


#############################
##### path per example ######
#############################

happy-path: all python-submitter upload-c++ config-c++ k8s-jobs

python-happy-path: all python-submitter  upload-python config-python k8s-jobs

python-quant-lib-path: all upload-python-ql config-python-ql k8s-jobs

dotnet50-path: all dotnet5.0-htcgrid-api upload-dotnet5.0 mock-submitter mock-config-dotnet5.0 k8s-jobs

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

