CURRENT_DIR:=$(shell pwd)
DIST_DIR?=$(shell pwd)/../../dist
BUILD_TYPE?=Release

.PHONY: clean all upload build-mock

all: upload


build-mock:
	#dotnet restore --no-cache
	dotnet nuget locals global-packages -c
	dotnet build --configuration $(BUILD_TYPE) .
	mkdir -p ./lib
	cp -v Client/bin/$(BUILD_TYPE)/net5.0/HtcCommon.dll ./lib
ifeq ($(BUILD_TYPE), Debug)
	cp -v Client/bin/$(BUILD_TYPE)/net5.0/HtcCommon.pdb ./lib
endif
	dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0
	

upload: build-mock
	$(MAKE) -C ./Server upload BUILD_TYPE=$(BUILD_TYPE)

clean:
	dotnet clean --configuration $(BUILD_TYPE) .
	rm -f ./lib/*.dll


