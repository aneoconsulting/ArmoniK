# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

SUBMITTER_IMAGE_NAME=submitter
TAG=mainline
GENERATED?=generated
REDIS_CERTIFICATES_DIRECTORY=
DOCKER_REGISTRY=
HTTP_PROXY=
HTTPS_PROXY=
NO_PROXY=
DOCKER_REGISTRY_WITH_SUFFIX=$(shell if [ "$(DOCKER_REGISTRY)" != "" ]; then echo "$(DOCKER_REGISTRY)/"; else echo ""; fi)

.PHONY: clean generated
all: generated

generated:
	mkdir -p $(GENERATED) && cat single-task-test.yaml.tpl | sed "s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{redis_certificates_directory}}%$(REDIS_CERTIFICATES_DIRECTORY)%;s%{{docker_registry}}%$(DOCKER_REGISTRY_WITH_SUFFIX)%;s%{{image_name}}%$(SUBMITTER_IMAGE_NAME)%;s%{{image_tag}}%$(TAG)%" > $(GENERATED)/single-task-test.yaml

	mkdir -p $(GENERATED) && cat portfolio-pricing-single-trade.yaml.tpl | sed "s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{docker_registry}}%$(DOCKER_REGISTRY_WITH_SUFFIX)%;s%{{image_name}}%$(SUBMITTER_IMAGE_NAME)%;s%{{image_tag}}%$(TAG)%" > $(GENERATED)/portfolio-pricing-single-trade.yaml

	mkdir -p $(GENERATED) && cat portfolio-pricing-book.yaml.tpl | sed "s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{docker_registry}}%$(DOCKER_REGISTRY_WITH_SUFFIX)%;s%{{image_name}}%$(SUBMITTER_IMAGE_NAME)%;s%{{image_tag}}%$(TAG)%" > $(GENERATED)/portfolio-pricing-book.yaml

	mkdir -p $(GENERATED) && cat single-task-dotnet5.0.yaml.tpl | sed "s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{docker_registry}}%$(DOCKER_REGISTRY_WITH_SUFFIX)%;s%{{image_name}}%$(SUBMITTER_IMAGE_NAME)%;s%{{image_tag}}%$(TAG)%" > $(GENERATED)/single-task-dotnet5.0.yaml

	mkdir -p $(GENERATED) && cat local-single-task-dotnet5.0.yaml.tpl | sed "s%{{http_proxy}}%$(HTTP_PROXY)%;s%{{https_proxy}}%$(HTTPS_PROXY)%;s%{{no_proxy}}%$(NO_PROXY)%;s%{{redis_certificates_directory}}%$(REDIS_CERTIFICATES_DIRECTORY)%;s%{{docker_registry}}%$(DOCKER_REGISTRY_WITH_SUFFIX)%;s%{{image_name}}%$(SUBMITTER_IMAGE_NAME)%;s%{{image_tag}}%$(TAG)%" > $(GENERATED)/local-single-task-dotnet5.0.yaml


clean:
	rm -rf $(GENERATED)