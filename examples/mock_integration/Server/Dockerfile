FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build

RUN mkdir -p /app
WORKDIR "/app"

COPY ./mock_integration_image /app/mock_integration

WORKDIR "/app/mock_integration/src"
RUN mkdir -p ./dist/dotnet5.0
#COPY ./mock_integration_image/src/mock_integration/dist/dotnet5.0/HTCGridAPI.1.0.0.nupkg ./dist/dotnet5.0
COPY ./mock_integration_image/src/mock_integration/dist/dotnet5.0/*.nupkg ./dist/dotnet5.0/
RUN dotnet nuget add source /app/mock_integration/src/dist/dotnet5.0
RUN dotnet restore "mock_integration/mock_integration.csproj"

WORKDIR "/app/mock_integration/src/mock_integration"
RUN mkdir -p ./lib/




#COPY ./mock_integration_image/src/mock_integration/lib/Htc.Mock.dll ./lib/
COPY ./mock_integration_image/src/mock_integration/lib/HtcCommon.dll ./lib/
COPY ./mock_integration_image/src/mock_integration/dist/dotnet5.0/HttpApi.1.0.0.nupkg ./dist/dotnet5.0
RUN dotnet build "mock_integration.csproj" --configuration Release --output /app/build

FROM build AS publish
RUN dotnet publish "mock_integration.csproj" \
            --configuration Release \
            --runtime linux-x64  \
            --self-contained false \
            --output /app/publish \
            -p:PublishReadyToRun=true



RUN cp lambda_entry_point.sh /app/publish

FROM base AS final
RUN mkdir -p /var/task
WORKDIR /var/task
COPY --from=publish /app/publish .
RUN apt update ; apt install -y zip
RUN zip -9yr lambda.zip .
CMD cp lambda.zip /app
