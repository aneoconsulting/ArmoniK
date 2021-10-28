BUILD_TYPE?=Release
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY

.PHONY: clean

all: build


build: .
	dotnet restore && dotnet build "ArmonikExecutor.csproj" --configuration $(BUILD_TYPE)
	dotnet publish "ArmonikExecutor.csproj" \
        --configuration $(BUILD_TYPE) \
        --runtime linux-x64  \
        --self-contained false \
        --output $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Server \
        -p:PublishReadyToRun=true

image: build
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker build $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Server -t $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG) -f ./Dockerfile
else
	docker build $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Server -t lambda:$(ARMONIK_TAG) -f ./Dockerfile
endif


upload: image
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG)
endif

clean:
	rm -rf ./lib ./dist