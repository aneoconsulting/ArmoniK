# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


GENERATED?=$(shell pwd)/generated
BUILD_TYPE?=Release

.PHONY: all clean build-package bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll ${ARMONIK_NUGET_REPOS}/HTCGridAPI.$(HTCGridAPI).nupkg


all: build-package

bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll:
	dotnet restore && dotnet clean &&  dotnet build --configuration $(BUILD_TYPE)

${ARMONIK_NUGET_REPOS}/HTCGridAPI.$(HTCGridAPI).nupkg: bin/$(BUILD_TYPE)/net5.0/ref/HTCGridAPI.dll
	dotnet pack -c $(BUILD_TYPE) -o ${ARMONIK_NUGET_REPOS}

build-package: ${ARMONIK_NUGET_REPOS}/HTCGridAPI.$(HTCGridAPI).nupkg

clean:
	dotnet clean
	rm -rf ${ARMONIK_NUGET_REPOS}/HTCGridAPI.$(HTCGridAPI).*
	rm -rf obj bin
