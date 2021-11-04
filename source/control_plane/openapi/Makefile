# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

GENERATED?=$(shell pwd)/generated
SRCS    := api.yaml
DOCKER_USER_ID:=$(shell id -u)
DOCKER_GROUP_ID:=$(shell id -g)
SRCS    := api.yaml
BUILD_TYPE?=Release
PACKAGE_NAME=httpapi
PACKAGE_NAME_CSHARP=HttpApi
PACKAGE_TARGET=$(DIST_DIR)/$(PACKAGE_NAME)-$(HttpApi)-py3-none-any.whl
DOTNET50_PACKAGE_TARGET=$(DIST_DIR)/dotnet5.0/$(PACKAGE_NAME_CSHARP).$(HttpApi).nupkg

.PHONY: all clean

all: install-packages csharp-api-package csharp-server-package create-dotnet-package

clean:
	rm -rf $(GENERATED)/python $(GENERATED)/csharp
	
$(GENERATED)/python/http_api:
	mkdir -p $(GENERATED)/python/http_api
	
$(GENERATED)/csharp/http_api:
	mkdir -p $(GENERATED)/csharp/http_api
	
$(GENERATED)/csharp/http_server:
	mkdir -p $(GENERATED)/csharp/http_server

$(GENERATED)/python/http_api/setup.py: $(SRCS) $(GENERATED)/python/http_api
	docker run --user "$(DOCKER_USER_ID):$(DOCKER_GROUP_ID)" --rm  --mount "type=bind,src=$(GENERATED)/python/http_api,dst=/tmp/http_api" -v "$(shell pwd)/$(SRCS):/api.yaml" openapitools/openapi-generator-cli generate -i /api.yaml -g python -o /tmp/http_api  --additional-properties=packageName=$(PACKAGE_NAME) --additional-properties=packageVersion=$(HttpApi)

$(GENERATED)/csharp/http_api/README.md: $(SRCS) $(GENERATED)/csharp/http_api
	docker run --user "$(DOCKER_USER_ID):$(DOCKER_GROUP_ID)" --rm  --mount "type=bind,src=$(GENERATED)/csharp/http_api,dst=/tmp/http_api" -v "$(shell pwd)/$(SRCS):/api.yaml" openapitools/openapi-generator-cli generate -i /api.yaml -g  csharp-netcore -o /tmp/http_api  --additional-properties=targetFramework=net5.0 --additional-properties=packageName=$(PACKAGE_NAME_CSHARP) --additional-properties=packageVersion=$(HttpApi)

$(GENERATED)/csharp/http_server/README.md: $(SRCS) $(GENERATED)/csharp/http_server
	docker run  --user "$(DOCKER_USER_ID):$(DOCKER_GROUP_ID)" --rm  --mount "type=bind,src=$(GENERATED)/csharp/http_server,dst=/tmp/http_server" -v "$(shell pwd)/$(SRCS):/api.yaml" openapitools/openapi-generator-cli generate -i /api.yaml -g aspnetcore -o /tmp/http_server --additional-properties=aspnetCoreVersion=5.0 --additional-properties=packageName=$(PACKAGE_NAME_CSHARP) --additional-properties=packageVersion=$(HttpApi)

python-package: $(GENERATED)/python/http_api/setup.py

csharp-api-package: $(GENERATED)/csharp/http_api/README.md

csharp-server-package: $(GENERATED)/csharp/http_server/README.md

$(PACKAGE_TARGET): python-package
	cd $(GENERATED)/python/http_api/ && python setup.py bdist_wheel -d $(DIST_DIR)

$(DOTNET50_PACKAGE_TARGET): csharp-api-package
	sed "s%  </PropertyGroup>%  </PropertyGroup>\n  <PropertyGroup Condition=\" '\$$(Configuration)' == 'Debug' \">\n    <DebugType>embedded</DebugType>\n    <IncludeSymbols>true</IncludeSymbols>\n     <SymbolPackageFormat>snupkg</SymbolPackageFormat>\n  </PropertyGroup>%" -i $(GENERATED)/csharp/http_api/src/HttpApi/HttpApi.csproj
	cd $(GENERATED)/csharp/http_api/ && dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0

create-dotnet-package: $(DOTNET50_PACKAGE_TARGET)

install-packages: $(PACKAGE_TARGET)
	pip install --force-reinstall $(PACKAGE_TARGET)


