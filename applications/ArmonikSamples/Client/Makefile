SUBMITTER_IMAGE_NAME=submitter
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY
BUILD_TYPE?=Release

.PHONY: push

all: push

.PHONY: all clean

all: push

build: .
	dotnet restore && dotnet build "Client.csproj" --configuration $(BUILD_TYPE)
	dotnet publish "Client.csproj" \
        --configuration $(BUILD_TYPE) \
        --runtime linux-x64  \
        --self-contained false \
        --output $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Client \
        -p:PublishReadyToRun=true

image: build
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker build $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Client -t $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
else
	docker build $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Client -t $(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG) -f ./Dockerfile
endif

push: image
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG)
endif

clean:
	rm -rf ../dist 2>&1 > /dev/null || true