FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build


#WORKDIR "/app/mock_computation_image/src"
#RUN dotnet restore "mock_computation_image/mock_computation_image.csproj"
RUN apt-get update ; apt-get install -y build-essential
WORKDIR /app/SimpleClient
RUN mkdir -p ./lib/dotnet5.0
COPY ./dist/dotnet5.0/HTCGridAPI.1.0.0.nupkg ./lib/dotnet5.0
COPY ./dist/dotnet5.0/HttpApi.1.0.0.nupkg ./lib/dotnet5.0
#COPY ./examples/csharp/ClientTask.cs ./
COPY ./examples/client/csharp ./
RUN ls ./lib
RUN dotnet nuget add source /app/SimpleClient/lib/dotnet5.0
RUN dotnet restore
RUN make build-dotnet DIST_DIR=./lib GENERATED=/app/build

FROM build AS publish
RUN dotnet publish "SimpleClient.csproj" \
            --configuration Release \ 
            --runtime linux-x64  \
            --self-contained false \ 
            --output /app/publish \
            -p:PublishReadyToRun=true
RUN ls
WORKDIR /app/publish
RUN ls
ENTRYPOINT ["dotnet"]
