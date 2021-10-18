CURRENT_DIR:=$(shell pwd)
DIST_DIR?=./dist
BUILD_TYPE?=Release

.PHONY: clean all upload build client packages

all: client upload

client: external_packages
	mkdir -p dist lib
	cd Client && make BUILD_TYPE=$(BUILD_TYPE)

build: client

external_packages:
	mkdir -p ./dist
	cp -u ${ARMONIK_NUGET_REPOS}/*.nupkg ./dist

upload: external_packages
	$(MAKE) -C ./packages upload BUILD_TYPE=$(BUILD_TYPE)

clean:
	dotnet clean --configuration $(BUILD_TYPE) .
	rm -rf ./lib ./dist 2>&1 > /dev/null || true


