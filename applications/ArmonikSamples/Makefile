CURRENT_DIR:=$(shell pwd)
DIST_DIR?=./dist
BUILD_TYPE?=Release

.PHONY: clean all upload build client packages

all: client upload

client:
	mkdir -p dist lib
	cd client && make

build: client


upload:
	$(MAKE) -C ./packages upload BUILD_TYPE=$(BUILD_TYPE)

clean:
	dotnet clean --configuration $(BUILD_TYPE) .
	rm -rf ./lib ./dist 2>&1 > /dev/null || true


