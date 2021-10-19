# Copyright 2021 ANEO, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aneo.eu/apache-2-0/


GENERATED?=$(shell pwd)/generated
DIST_DIR?=$(shell pwd)/../../../../dist
BUILD_TYPE?=Release
ARMONIK_VERSION_API=1.0.0 #TODO Set the version from global env
PROJECT_NAME=Armonik.api
PACKAGE_NAME=$(PROJECT_NAME).$(ARMONIK_VERSION_API).nupkg

.PHONY: all clean build-package bin/$(BUILD_TYPE)/net5.0/ref/$(PROJECT_NAME).dll


all: build-package

bin/$(BUILD_TYPE)/net5.0/ref/$(PROJECT_NAME).dll:
	dotnet restore && dotnet clean && dotnet build -c $(BUILD_TYPE)

${ARMONIK_NUGET_REPOS}/$(PACKAGE_NAME): bin/$(BUILD_TYPE)/net5.0/ref/$(PROJECT_NAME).dll
ifeq ($(BUILD_TYPE), Debug)
	dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0 --include-source --include-symbols
	cp bin/$(BUILD_TYPE)/net5.0/*.pdb ${ARMONIK_NUGET_REPOS}
	cp bin/$(BUILD_TYPE)/net5.0/*.dll ${ARMONIK_NUGET_REPOS}
else
	dotnet pack -c $(BUILD_TYPE) -o ${ARMONIK_NUGET_REPOS}
endif

build-package: ${ARMONIK_NUGET_REPOS}/$(PACKAGE_NAME)

clean:
	dotnet clean
	rm -rf ${ARMONIK_NUGET_REPOS}/$(PACKAGE_NAME)

