# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


GENERATED?=$(shell pwd)/generated
DIST_DIR?=$(shell pwd)/../../../../dist
BUILD_TYPE?=Release

.PHONY: all clean build-package bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll $(DIST_DIR)/dotnet5.0/HTCGridAPI.$(HTCGridAPI).nupkg


all: build-package

bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll:
	dotnet restore && dotnet clean &&  dotnet build --configuration $(BUILD_TYPE)

$(DIST_DIR)/dotnet5.0/HTCGridAPI.$(HTCGridAPI).nupkg: bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll
	dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0

build-package: $(DIST_DIR)/dotnet5.0/HTCGridAPI.$(HTCGridAPI).nupkg

clean:
	dotnet clean
	rm -rf $(DIST_DIR)/dotnet5.0/HTCGridAPI.$(HTCGridAPI).*
	rm -rf obj bin
