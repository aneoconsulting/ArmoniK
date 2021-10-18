FROM public.ecr.aws/lambda/dotnet:5.0 as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build

WORKDIR "/app"
COPY ./packages/images /app/images

WORKDIR "/app/images"
RUN mkdir -p ./dist
COPY ./dist/*.nupkg ./dist/
ENV ARMONIK_NUGET_REPOS=/app/images/dist

WORKDIR "/app/images"
RUN dotnet restore
RUN mkdir -p ./lib/

#COPY ./packages/images/dist/dotnet5.0/HttpApi.1.0.0.nupkg ./dist/dotnet5.0
RUN dotnet build "ArmonikExecutor.csproj" --configuration Release --output /app/build

FROM build AS publish
RUN dotnet publish "ArmonikExecutor.csproj" \
            --configuration Release \
            --runtime linux-x64  \
            --self-contained false \
            --output /app/publish \
            -p:PublishReadyToRun=true

RUN cp lambda_entry_point.sh /app/publish

FROM base AS final
WORKDIR /var/task
COPY --from=publish /app/publish .
