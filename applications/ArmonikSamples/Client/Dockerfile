FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build

ARG HTCGRID_PACKAGE
ARG HTTPAPI_PACKAGE
ARG ARMONIKAPI_PACKAGE


ENV HTCGRID_PACKAGE=${HTCGRID_PACKAGE}
ENV HTTPAPI_PACKAGE=${HTTPAPI_PACKAGE}
ENV ARMONIKAPI_PACKAGE=${ARMONIKAPI_PACKAGE}


RUN apt-get update -y; apt-get install -y build-essential
WORKDIR /app/sample
RUN mkdir -p ./lib/dotnet5.0

#Since Docker can't access to file ouside working path.
#Need copy nupkg in dist directory
COPY ./dist/${HTCGRID_PACKAGE} ./lib/dotnet5.0
COPY ./dist/${HTTPAPI_PACKAGE} ./lib/dotnet5.0
COPY ./dist/${ARMONIKAPI_PACKAGE} ./lib/dotnet5.0

#Copy client project to be build in docker container
COPY ./Client ./Client

RUN ls ./lib
RUN ls -la ./Client/nuget.config
ENV ARMONIK_NUGET_REPOS=/app/sample/lib/dotnet5.0
RUN echo $ARMONIK_NUGET_REPOS
RUN ls $ARMONIK_NUGET_REPOS
WORKDIR /app/sample/Client
RUN dotnet restore
RUN dotnet build "Client.csproj" --configuration Release

FROM build AS publish
RUN dotnet publish "Client.csproj" \
            --configuration Release \
            --runtime linux-x64  \
            --self-contained false \
            --output /app/publish \
            -p:PublishReadyToRun=true
RUN ls
WORKDIR /app/publish
RUN ls
ENTRYPOINT ["dotnet"]
