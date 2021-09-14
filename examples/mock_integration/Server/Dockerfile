FROM public.ecr.aws/lambda/dotnet:5.0 as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build

WORKDIR "/app"
COPY ./mock_integration_image /app/mock_integration

WORKDIR "/app/mock_integration/src"
RUN mkdir -p ./dist/dotnet5.0
COPY ./mock_integration_image/src/mock_integration/dist/dotnet5.0/*.nupkg ./dist/dotnet5.0/
ENV HTCGRID_NUGET_REPOS=/app/mock_integration/src/dist/dotnet5.0

WORKDIR "/app/mock_integration/src/mock_integration"
RUN dotnet restore
RUN mkdir -p ./lib/


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
WORKDIR /var/task
COPY --from=publish /app/publish .
