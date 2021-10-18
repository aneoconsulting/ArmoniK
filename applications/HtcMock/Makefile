CURRENT_DIR:=$(shell pwd)
DIST_DIR?=$(shell pwd)/../../dist
BUILD_TYPE?=Release

.PHONY: clean all upload build-mock

all: client upload

client: external_packages
	$(MAKE) -C ./Client BUILD_TYPE=$(BUILD_TYPE)

server: external_packages
	$(MAKE) -C ./Server upload BUILD_TYPE=$(BUILD_TYPE)

external_packages:
	mkdir -p dist lib
	dotnet nuget locals global-packages -c
	cp -u ${ARMONIK_NUGET_REPOS}/*.nupkg ./dist


upload: server



clean:
	$(MAKE) -C ./Client clean BUILD_TYPE=$(BUILD_TYPE)
	$(MAKE) -C ./Server clean BUILD_TYPE=$(BUILD_TYPE)
	rm -f ./lib/*.dll


