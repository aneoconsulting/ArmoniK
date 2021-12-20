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

include nuget-versions.txt
export $(shell sed 's/=.*//' nuget-versions.txt )

.PHONY: all utils api lambda submitter packages test test-api test-utils test-agent lambda-control-plane

all: build-all-infra
build-all-infra: local-app-configs app-configs k8s-jobs all-images

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

apply-dotnet-runtime: app-configs
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

apply-dotnet-local-runtime: local-app-configs
	@$(MAKE) -C ./local_deployment/grid/terraform apply GRID_CONFIG=$(GENERATED)/local_dotnet5.0_runtime_grid_config.json

destroy-dotnet-local-runtime:
	@$(MAKE) -C ./local_deployment/grid/terraform destroy GRID_CONFIG=$(GENERATED)/local_dotnet5.0_runtime_grid_config.json

clean-grid-local-deployment:
	@$(MAKE) -C ./local_deployment/grid/terraform clean

clean-grid-local-project:
	rm -rf $(GENERATED) $(DIST_DIR) applications/$(ARMONIK_APPLICATION_NAME)/Client/bin/ applications/$(ARMONIK_APPLICATION_NAME)/Client/obj/ applications/$(ARMONIK_APPLICATION_NAME)/packages/bin/ applications/$(ARMONIK_APPLICATION_NAME)/packages/obj/

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

app-configs:
	@$(MAKE) -C ./applications/apps_core/configurations generated-dotnet5.0 FILE_HANDLER=$(FILE_HANDLER) BUILD_TYPE=$(BUILD_TYPE)

local-app-configs:
	@$(MAKE) -C ./applications/apps_core/configurations generated-local-dotnet5.0 FILE_HANDLER=$(FILE_HANDLER) BUILD_TYPE=$(BUILD_TYPE)


########################################
##### Build Armonik dependencies #######
########################################

build-htc-grid-api: build-htc-grid-api-internal
build-htc-grid-api-internal:
	$(MAKE) -C ./source/HTCGridAPI all BUILD_TYPE=$(BUILD_TYPE)

build-armonik-api: build-htc-grid-api build-armonik-api-internal
build-armonik-api-internal:
	$(MAKE) -C ./source/Armonik.api all BUILD_TYPE=$(BUILD_TYPE)

clean-app:
	rm -rf dist/ generated/
	$(MAKE) -C ./source/Armonik.api clean
	$(MAKE) -C ./applications/$(ARMONIK_APPLICATION_NAME) clean


#############################
##### building images #######
#############################

all-images: armonik-full image-agent

sample-app: upload-submitter upload-server

armonik-full: build-armonik-api sample-app

upload-submitter:
	$(MAKE) -C ./applications/$(ARMONIK_APPLICATION_NAME) client BUILD_TYPE=$(BUILD_TYPE)

upload-server:
	$(MAKE) -C ./applications/$(ARMONIK_APPLICATION_NAME) server BUILD_TYPE=$(BUILD_TYPE)

