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
	dotnet pack -c $(BUILD_TYPE) -o ${ARMONIK_NUGET_REPOS}

build-package: ${ARMONIK_NUGET_REPOS}/$(PACKAGE_NAME)

clean:
	dotnet clean
	rm -rf ${ARMONIK_NUGET_REPOS}/$(PACKAGE_NAME)
	rm -rf bin obj
