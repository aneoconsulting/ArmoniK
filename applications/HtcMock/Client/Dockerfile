FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build


RUN apt-get update ; apt-get install -y build-essential
WORKDIR /app
RUN mkdir -p ./lib/
COPY ./dist/*.nupkg ./lib/

COPY ./Client ./Client
ENV ARMONIK_NUGET_REPOS=/app/lib
RUN echo $ARMONIK_NUGET_REPOS


WORKDIR /app/Client
RUN dotnet restore
RUN dotnet build "Client.csproj" --configuration Release

FROM build AS publish
RUN dotnet publish "Client.csproj" \
            --configuration Release \
            --runtime linux-x64  \
            --self-contained false \
            --output /app/publish \
            -p:PublishReadyToRun=true

WORKDIR /app/publish
ENTRYPOINT ["dotnet"]
