# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

TAG=mainline
GENERATED?=generated
BUCKET_NAME=
FILE_HANDLER=
FUNCTION_HANDLER=
TASKS_TABLE_SERVICE=
QUEUE_SERVICE=
REGION=
ACCOUNT_ID=
BUCKET_NAME=
DOCKER_REGISTRY=
REDIS_CERTIFICATES_DIRECTORY=
API_GATEWAY_SERVICE=
QUEUE=$(shell if [ "$(QUEUE_SERVICE)" != "" ]; then echo "$(QUEUE_SERVICE)"; else echo "PrioritySQS"; fi)
TABLE=$(shell if [ "$(TASKS_TABLE_SERVICE)" != "" ]; then echo "$(TASKS_TABLE_SERVICE)"; else echo "DynamoDB"; fi)
export HTTP_PROXY
export HTTPS_PROXY
export NO_PROXY
export http_proxy
export https_proxy
export no_proxy

generated-c++: grid_config.json.tpl
	mkdir -p $(GENERATED) && cat grid_config.json.tpl | sed "s%{{docker_registry}}%$(DOCKER_REGISTRY)%;s%{{certificates_dir_path}}%$(REDIS_CERTIFICATES_DIRECTORY)%;s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{http_proxy_lower}}%$(http_proxy)%;s%{{https_proxy_lower}}%$(https_proxy)%;s%{{no_proxy_lower}}%$(no_proxy)%;s%{{grid_queue_service}}%$(QUEUE)%;s%{{tasks_status_table_service}}%$(TABLE)%;s%{{region}}%$(REGION)%;s%{{workload_bucket_name}}%$(BUCKET_NAME)%;s%{{image_tag}}%$(TAG)%;s%{{account_id}}%${ACCOUNT_ID}%;s%{{api_gateway_service}}%$(API_GATEWAY_SERVICE)%" > $(GENERATED)/grid_config.json
	sed -r '/no_proxy/s/,/\\\\,/g;/no_proxy/s/\\\\,$$/,/g' -i $(GENERATED)/grid_config.json

generated-s3-c++: custom_runtime_s3_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat custom_runtime_s3_grid_config.json.tpl | sed "s%{{docker_registry}}%$(DOCKER_REGISTRY)%;s%{{certificates_dir_path}}%$(REDIS_CERTIFICATES_DIRECTORY)%;s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{http_proxy_lower}}%$(http_proxy)%;s%{{https_proxy_lower}}%$(https_proxy)%;s%{{no_proxy_lower}}%$(no_proxy)%;s%{{grid_queue_service}}%$(QUEUE)%;s%{{tasks_status_table_service}}%$(TABLE)%;s%{{region}}%$(REGION)%;s%{{workload_bucket_name}}%$(BUCKET_NAME)%;s%{{image_tag}}%$(TAG)%;s%{{account_id}}%${ACCOUNT_ID}%;s%{{api_gateway_service}}%$(API_GATEWAY_SERVICE)%" > $(GENERATED)/custom_runtime_s3_grid_config.json
	sed -r '/no_proxy/s/,/\\\\,/g;/no_proxy/s/\\\\,$$/,/g' -i $(GENERATED)/custom_runtime_s3_grid_config.json

generated-python: python_runtime_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat python_runtime_grid_config.json.tpl | sed "s%{{docker_registry}}%$(DOCKER_REGISTRY)%;s%{{certificates_dir_path}}%$(REDIS_CERTIFICATES_DIRECTORY)%;s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{http_proxy_lower}}%$(http_proxy)%;s%{{https_proxy_lower}}%$(https_proxy)%;s%{{no_proxy_lower}}%$(no_proxy)%;s%{{grid_queue_service}}%$(QUEUE)%;s%{{tasks_status_table_service}}%$(TABLE)%;s%{{python_file_handler}}%$(FILE_HANDLER)%;s%{{python_function_handler}}%$(FUNCTION_HANDLER)%;s%{{region}}%$(REGION)%;s%{{workload_bucket_name}}%$(BUCKET_NAME)%;s%{{image_tag}}%$(TAG)%;s%{{account_id}}%${ACCOUNT_ID}%;s%{{api_gateway_service}}%$(API_GATEWAY_SERVICE)%" > $(GENERATED)/python_runtime_grid_config.json
	sed -r '/no_proxy/s/,/\\\\,/g;/no_proxy/s/\\\\,$$/,/g' -i $(GENERATED)/python_runtime_grid_config.json

generated-dotnet5.0: dotnet5.0_runtime_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat dotnet5.0_runtime_grid_config.json.tpl | sed "s%{{docker_registry}}%$(DOCKER_REGISTRY)%;s%{{certificates_dir_path}}%$(REDIS_CERTIFICATES_DIRECTORY)%;s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{http_proxy_lower}}%$(http_proxy)%;s%{{https_proxy_lower}}%$(https_proxy)%;s%{{no_proxy_lower}}%$(no_proxy)%;s%{{grid_queue_service}}%$(QUEUE)%;s%{{tasks_status_table_service}}%$(TABLE)%;s%{{dotnet50_file_handler}}%$(FILE_HANDLER)%;s%{{region}}%$(REGION)%;s%{{workload_bucket_name}}%$(BUCKET_NAME)%;s%{{image_tag}}%$(TAG)%;s%{{account_id}}%${ACCOUNT_ID}%;s%{{api_gateway_service}}%$(API_GATEWAY_SERVICE)%" > $(GENERATED)/dotnet5.0_runtime_grid_config.json
	sed -r '/no_proxy/s/,/\\\\,/g;/no_proxy/s/\\\\,$$/,/g' -i $(GENERATED)/dotnet5.0_runtime_grid_config.json

generated-local-dotnet5.0: local_dotnet5.0_runtime_grid_config.json.tpl
	mkdir -p $(GENERATED) && cat local_dotnet5.0_runtime_grid_config.json.tpl | sed "s%{{docker_registry}}%$(DOCKER_REGISTRY)%;s%{{certificates_dir_path}}%$(REDIS_CERTIFICATES_DIRECTORY)%;s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{http_proxy_lower}}%$(http_proxy)%;s%{{https_proxy_lower}}%$(https_proxy)%;s%{{no_proxy_lower}}%$(no_proxy)%;s%{{grid_queue_service}}%$(QUEUE)%;s%{{tasks_status_table_service}}%$(TABLE)%;s%{{dotnet50_file_handler}}%$(FILE_HANDLER)%;s%{{region}}%$(REGION)%;s%{{workload_bucket_name}}%$(BUCKET_NAME)%;s%{{image_tag}}%$(TAG)%;s%{{account_id}}%${ACCOUNT_ID}%;s%{{api_gateway_service}}%$(API_GATEWAY_SERVICE)%" > $(GENERATED)/local_dotnet5.0_runtime_grid_config.json
	sed -r '/no_proxy/s/,/\\\\,/g;/no_proxy/s/\\\\,$$/,/g' -i $(GENERATED)/local_dotnet5.0_runtime_grid_config.json


clean:
	rm -rf $(GENERATED)