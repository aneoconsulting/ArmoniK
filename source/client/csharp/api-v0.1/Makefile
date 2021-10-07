# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


GENERATED?=$(shell pwd)/generated
DIST_DIR?=$(shell pwd)/../../../../dist
BUILD_TYPE?=Release

.PHONY: all clean build-package bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll $(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg 


all: build-package

bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll:
	dotnet restore && dotnet clean &&  dotnet build --configuration $(BUILD_TYPE)

$(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg: bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll
ifeq ($(BUILD_TYPE), Debug)
	dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0 --include-source --include-symbols
	cp bin/$(BUILD_TYPE)/net5.0/*.pdb $(DIST_DIR)/dotnet5.0
	cp bin/$(BUILD_TYPE)/net5.0/*.dll $(DIST_DIR)/dotnet5.0
else
	dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0
endif

build-package: $(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg

clean:
	dotnet clean
	rm -rf $(DIST_DIR)/dotnet5.0/HTCGridAPI.1.0.0.nupkg

