BUILD_TYPE?=Release

.PHONY: clean all client server armonikmock

all: client server armonikmock

armonikmock:
	$(MAKE) -C ./ArmonikMock all BUILD_TYPE=$(BUILD_TYPE)

client: armonikmock
	$(MAKE) -C ./Client upload BUILD_TYPE=$(BUILD_TYPE)

server: armonikmock
	$(MAKE) -C ./Server upload BUILD_TYPE=$(BUILD_TYPE)

clean:
	$(MAKE) -C ./Client clean
	$(MAKE) -C ./Server clean
	$(MAKE) -C ./ArmonikMock clean
