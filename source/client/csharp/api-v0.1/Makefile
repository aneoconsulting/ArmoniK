# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


GENERATED?=$(shell pwd)/generated
DIST_DIR?=$(shell pwd)/../../../dist
BUILD_TYPE?=Release

.PHONY: all clean


all: build-package

add-apis: $(DIST_DIR)/dotnet5.0/HttpApi.1.0.0.nupkg
	dotnet add package -s ../../../../dist/dotnet5.0/  HttpApi

bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll: add-apis
	dotnet clean && dotnet build --configuration $(BUILD_TYPE)

$(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg: bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll
	dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0

build-package: $(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg

clean:
	dotnet clean
	rm -rf $(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg

