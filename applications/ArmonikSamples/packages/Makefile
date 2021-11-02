BUILD_TYPE?=Release
export ARMONIK_TAG
export ARMONIK_DOCKER_REGISTRY

DOCKER_IMG=$(shell if [ "$(ARMONIK_DOCKER_REGISTRY)" != "" ]; then echo "$(ARMONIK_DOCKER_REGISTRY)/lambda"; else echo "lambda"; fi)
DOCKERFILE=$(shell if [ "${BUILD_TYPE}" = "Debug" ]; then echo "./Dockerfile_Debug"; else echo "./Dockerfile"; fi)

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
	docker build $(GENERATED)/$(ARMONIK_APPLICATION_NAME)/Server -t $(DOCKER_IMG):$(ARMONIK_TAG) -f $(DOCKERFILE)


upload: image
ifneq ($(ARMONIK_DOCKER_REGISTRY),)
	docker push $(ARMONIK_DOCKER_REGISTRY)/lambda:$(ARMONIK_TAG)
endif

clean:
	dotnet clean
	rm -rf bin/ obj/