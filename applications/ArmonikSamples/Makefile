CURRENT_DIR:=$(shell pwd)
DIST_DIR?=./dist
BUILD_TYPE?=Release

.PHONY: clean all client server

all: client server

client:
	$(MAKE) -C ./Client upload BUILD_TYPE=$(BUILD_TYPE)

server:
	$(MAKE) -C ./packages upload BUILD_TYPE=$(BUILD_TYPE)

clean:
	dotnet clean --configuration $(BUILD_TYPE) .
	rm -rf ./lib ./dist 2>&1 > /dev/null || true


