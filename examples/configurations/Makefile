# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

export ARMONIK_TAG
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY
export ARMONIK_TASKS_TABLE_SERVICE
GENERATED?=generated
FILE_HANDLER=
QUEUE_SERVICE=
REGION=
ACCOUNT_ID=
DOCKER_REGISTRY=
API_GATEWAY_SERVICE=

generated-dotnet5.0: dotnet5.0_runtime_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat dotnet5.0_runtime_grid_config.json.tpl | sed "s|{{docker_registry}}|$(DOCKER_REGISTRY)|;s|{{certificates_dir_path}}|$(ARMONIK_REDIS_CERTIFICATES_DIRECTORY)|;s|{{grid_queue_service}}|$(QUEUE_SERVICE)|;s|{{tasks_status_table_service}}|$(ARMONIK_TASKS_TABLE_SERVICE)|;s|{{dotnet50_file_handler}}|$(FILE_HANDLER)|;s|{{region}}|$(REGION)|;s|{{image_tag}}|$(ARMONIK_TAG)|;s|{{account_id}}|${ACCOUNT_ID}|;s|{{api_gateway_service}}|$(API_GATEWAY_SERVICE)|" > $(GENERATED)/dotnet5.0_runtime_grid_config.json

generated-local-dotnet5.0: local_dotnet5.0_runtime_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat local_dotnet5.0_runtime_grid_config.json.tpl | sed "s|{{docker_registry}}|$(DOCKER_REGISTRY)|;s|{{certificates_dir_path}}|$(ARMONIK_REDIS_CERTIFICATES_DIRECTORY)|;s|{{grid_queue_service}}|$(QUEUE_SERVICE)|;s|{{tasks_status_table_service}}|$(ARMONIK_TASKS_TABLE_SERVICE)|;s|{{dotnet50_file_handler}}|$(FILE_HANDLER)|;s|{{region}}|$(REGION)|;s|{{image_tag}}|$(ARMONIK_TAG)|;s|{{account_id}}|${ACCOUNT_ID}|;s|{{api_gateway_service}}|$(API_GATEWAY_SERVICE)|" > $(GENERATED)/local_dotnet5.0_runtime_grid_config.json

clean:
	rm -rf $(GENERATED)