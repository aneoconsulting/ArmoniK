CURRENT_DIR:=$(shell pwd)
BUILD_TYPE?=Release

.PHONY: clean all client server

all: client server

client:
	$(MAKE) -C ./Client upload BUILD_TYPE=$(BUILD_TYPE)

server:
	$(MAKE) -C ./Server upload BUILD_TYPE=$(BUILD_TYPE)

clean:
	$(MAKE) -C ./Client clean
	$(MAKE) -C ./Server clean


