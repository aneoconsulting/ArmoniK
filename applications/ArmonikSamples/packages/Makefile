BUILD_TYPE?=Release
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY

.PHONY: clean

all: build


build: Dockerfile import-dll
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build .. -f ./Dockerfile_Debug -t $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG) --progress=plain
else
	docker build .. -f ./Dockerfile -t $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG) --progress=plain
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build .. -f ./Dockerfile_Debug -t lambda:$(ARMONIK_TAG) --progress=plain
else
	docker build .. -f ./Dockerfile -t lambda:$(ARMONIK_TAG) --progress=plain
endif
endif

upload: build
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG)
endif

import-dll:
	mkdir -p ./images/lib/
	mkdir -p ./images/dist
	cp -v ../lib/*.dll ./packages/images/lib/ || true
	cp -v ${ARMONIK_NUGET_REPOS}/*.nupkg ./images/dist/

clean:
	rm -rf ./images/lib ./images/dist