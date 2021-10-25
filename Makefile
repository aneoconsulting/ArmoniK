# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

export AGENT_IMAGE_NAME=agent
export SUBMITTER_IMAGE_NAME=submitter
export GENERATED=$(shell pwd)/generated
export DIST_DIR=$(shell pwd)/dist
export ARMONIK_CONFIG_TYPE?=CUSTOM
export ARMONIK_APPLICATION_NAME?=ArmonikSamples

BUILD_TYPE?=Release
PACKAGE_DIR:=./dist
PACKAGES:= $(wildcard $(PACKAGE_DIR)/*.whl)

.PHONY: all utils api lambda submitter packages test test-api test-utils test-agent lambda-control-plane

all: app-configs k8s-jobs all-images


###############################################
#######     Manage HTC grid states     ########
###############################################

init-grid-state:
	$(MAKE) -C ./deployment/init_grid/cloudformation init

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

show-password:
	@$(MAKE) -C ./deployment/grid/terraform get-grafana-password

clean-grid-deployment:
	@$(MAKE) -C ./deployment/grid/terraform clean

clean-grid-project:
	rm -rf $(GENERATED) $(DIST_DIR) envvars.conf

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

clean-grid-local-project:
	rm -rf $(GENERATED) $(DIST_DIR) envvars.conf

####################################
##### building documentation #######
####################################
doc: import
	mkdocs build

serve: import
	mkdocs serve

import: packages $(PACKAGES)
	pip install --force-reinstall $(PACKAGES)


###############################
##### generate k8s jobs #######
###############################
k8s-jobs:
	@$(MAKE) -C ./applications/apps_core/submissions/k8s_jobs


#############################
##### generate config #######
#############################
FILE_HANDLER="$(ARMONIK_APPLICATION_NAME)::$(ARMONIK_APPLICATION_NAME).Function::FunctionHandler"

app-configs: $(ARMONIK_APPLICATION_NAME)-config-dotnet5.0 $(ARMONIK_APPLICATION_NAME)-config-local-dotnet5.0

$(ARMONIK_APPLICATION_NAME)-config-dotnet5.0:
	@$(MAKE) -C ./applications/apps_core/configurations generated-dotnet5.0 FILE_HANDLER=$(FILE_HANDLER) BUILD_TYPE=$(BUILD_TYPE)

$(ARMONIK_APPLICATION_NAME)-config-local-dotnet5.0:
	@$(MAKE) -C ./applications/apps_core/configurations generated-local-dotnet5.0 FILE_HANDLER=$(FILE_HANDLER) BUILD_TYPE=$(BUILD_TYPE)


########################################
##### Build Armonik dependencies #######
########################################

http-apis:
	$(MAKE) -C ./source/control_plane/openapi/ all BUILD_TYPE=$(BUILD_TYPE)

utils:
	$(MAKE) -C ./source/client/python/utils

api: http-apis
	$(MAKE) -C ./source/client/python/api-v0.1

build-dotnet5.0-api: http-apis
	cd ./generated/csharp/http_api/ && dotnet restore src/HttpApi/ && dotnet build src/HttpApi/ --configuration $(BUILD_TYPE)

build-htc-grid-dotnet5.0-api: build-dotnet5.0-api
	$(MAKE) -C ./source/client/csharp/api-v0.1 all BUILD_TYPE=$(BUILD_TYPE)

build-armonik-dotnet5.0-api: build-htc-grid-dotnet5.0-api
	$(MAKE) -C ./source/control_plane/csharp/Armonik.api all BUILD_TYPE=$(BUILD_TYPE)



#############################
##### building images #######
#############################

all-images: sample-app-with-dep image-agent lambda-control-plane

sample-app: upload-dotnet5.0-submitter upload-dotnet5.0-server

sample-app-with-dep: build-armonik-dotnet5.0-api sample-app

upload-dotnet5.0-submitter:
	$(MAKE) -C ./applications/$(ARMONIK_APPLICATION_NAME) client BUILD_TYPE=$(BUILD_TYPE)

upload-dotnet5.0-server:
	$(MAKE) -C ./applications/$(ARMONIK_APPLICATION_NAME) upload BUILD_TYPE=$(BUILD_TYPE)

image-agent: utils api
	$(MAKE) -C ./source/compute_plane/python/agent

lambda-control-plane: lambda-control-plane-submit-tasks lambda-control-plane-get-results lambda-control-plane-cancel-tasks lambda-control-plane-ttl-checker

lambda-control-plane-submit-tasks: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/submit_tasks

lambda-control-plane-get-results: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/get_results

lambda-control-plane-cancel-tasks: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/cancel_tasks

lambda-control-plane-ttl-checker: utils api
	$(MAKE) -C ./source/control_plane/python/lambda/ttl_checker

