SUBMITTER_IMAGE_NAME=submitter
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY
BUILD_TYPE?=Release
HTCGRID_PACKAGE=HTCGridAPI.1.0.0.nupkg
HTTPAPI_PACKAGE=HttpApi.1.0.0.nupkg
ARMONIKAPI_PACKAGE=Armonik.api.1.0.0.nupkg

.PHONY: push

all: push

.PHONY: all clean external_packages

all: push

build: external_packages Dockerfile Dockerfile_Debug
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
ifeq ($(BUILD_TYPE), Debug)
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile_Debug
else
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif
else
ifeq ($(BUILD_TYPE), Debug)
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile_Debug
else
	docker build ../ \
	--build-arg HTCGRID_PACKAGE=$(HTCGRID_PACKAGE) \
	--build-arg HTTPAPI_PACKAGE=$(HTTPAPI_PACKAGE) \
	--build-arg ARMONIKAPI_PACKAGE=$(ARMONIKAPI_PACKAGE) \
	--build-arg NUGET_LOCAL_REPOS=${ARMONIK_NUGET_REPOS} \
	-t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif
endif

push: build
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG)
endif

clean:
	rm -rf ../dist 2>&1 > /dev/null || true