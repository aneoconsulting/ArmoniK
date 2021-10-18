CURRENT_DIR:=$(shell pwd)
DIST_DIR?=./dist
BUILD_TYPE?=Release

.PHONY: clean all upload build client

all: client upload

client:
	mkdir -p dist lib
	cd client && make

build: client

upload:
	@echo "nothing to do"

clean:
	rm -rf ./lib ./dist 2>&1 > /dev/null || true


