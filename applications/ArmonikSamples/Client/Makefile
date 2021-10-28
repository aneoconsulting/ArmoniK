SUBMITTER_IMAGE_NAME=submitter
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY
BUILD_TYPE?=Release

DOCKER_IMG=$(shell if [ "$(ARMONIK_DOCKER_REGISTRY)" != "" ]; then echo "$(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME)"; else echo "$(SUBMITTER_IMAGE_NAME)"; fi)
DOCKERFILE=$(shell if [ "$(BUILD_TYPE)" == "Debug" ]; then echo "./Dockerfile_Debug"; else echo "./Dockerfile"; fi)

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
	docker build $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Client -t $(DOCKER_IMG):$(ARMONIK_TAG) -f $(DOCKERFILE)

upload: image
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/$(SUBMITTER_IMAGE_NAME):$(ARMONIK_TAG)
endif

clean:
	rm -rf ../dist 2>&1 > /dev/null || true