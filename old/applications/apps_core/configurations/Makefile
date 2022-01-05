# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

export ARMONIK_TAG
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY
export ARMONIK_TASKS_TABLE_SERVICE
export ARMONIK_QUEUE_SERVICE
export ARMONIK_DOCKER_REGISTRY
export ARMONIK_API_GATEWAY_SERVICE
export ARMONIK_REGION
export ARMONIK_ACCOUNT_ID
export ARMONIK_CLUSTER_CONFIG
export ARMONIK_IMAGE_PULL_POLICY
export ARMONIK_REDIS_SECRETS

GENERATED?=generated
FILE_HANDLER=

generated-dotnet5.0: dotnet5.0_runtime_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat dotnet5.0_runtime_grid_config.json.tpl | sed "s|{{redis_secrets}}|$(ARMONIK_REDIS_SECRETS)|;s|{{generated_dir_path}}|$(GENERATED)|;s|{{image_pull_policy}}|$(ARMONIK_IMAGE_PULL_POLICY)|;s|{{cluster_config}}|$(ARMONIK_CLUSTER_CONFIG)|;s|{{docker_registry}}|$(ARMONIK_DOCKER_REGISTRY)|;s|{{certificates_dir_path}}|$(ARMONIK_REDIS_CERTIFICATES_DIRECTORY)|;s|{{grid_queue_service}}|$(ARMONIK_QUEUE_SERVICE)|;s|{{tasks_status_table_service}}|$(ARMONIK_TASKS_TABLE_SERVICE)|;s|{{dotnet50_file_handler}}|$(FILE_HANDLER)|;s|{{region}}|$(ARMONIK_REGION)|;s|{{image_tag}}|$(ARMONIK_TAG)|;s|{{account_id}}|${ARMONIK_ACCOUNT_ID}|;s|{{api_gateway_service}}|$(ARMONIK_API_GATEWAY_SERVICE)|" > $(GENERATED)/dotnet5.0_runtime_grid_config.json

generated-local-dotnet5.0: local_dotnet5.0_runtime_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat local_dotnet5.0_runtime_grid_config.json.tpl | sed "s|{{persistent_volume_host_path}}|$(GENERATED)/libraries|;s|{{redis_secrets}}|$(ARMONIK_REDIS_SECRETS)|;s|{{generated_dir_path}}|$(GENERATED)|;s|{{image_pull_policy}}|$(ARMONIK_IMAGE_PULL_POLICY)|;s|{{cluster_config}}|$(ARMONIK_CLUSTER_CONFIG)|;s|{{docker_registry}}|$(ARMONIK_DOCKER_REGISTRY)|;s|{{certificates_dir_path}}|$(ARMONIK_REDIS_CERTIFICATES_DIRECTORY)|;s|{{grid_queue_service}}|$(ARMONIK_QUEUE_SERVICE)|;s|{{tasks_status_table_service}}|$(ARMONIK_TASKS_TABLE_SERVICE)|;s|{{dotnet50_file_handler}}|$(FILE_HANDLER)|;s|{{region}}|$(ARMONIK_REGION)|;s|{{image_tag}}|$(ARMONIK_TAG)|;s|{{account_id}}|${ARMONIK_ACCOUNT_ID}|;s|{{api_gateway_service}}|$(ARMONIK_API_GATEWAY_SERVICE)|" > $(GENERATED)/local_dotnet5.0_runtime_grid_config.json

clean:
	rm -rf $(GENERATED)