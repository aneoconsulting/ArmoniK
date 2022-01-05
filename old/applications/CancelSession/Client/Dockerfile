FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build


RUN apt-get update ; apt-get install -y build-essential
WORKDIR /app/
RUN mkdir -p ./lib/
COPY ./dist/HTCGridAPI.*.nupkg ./lib/
COPY ./dist/HttpApi.*.nupkg ./lib/
COPY ./dist/Armonik.api.* ./lib/

COPY ./Client ./Client
RUN ls ./lib
RUN ls -la ./Client/nuget.config
ENV ARMONIK_NUGET_REPOS=/app/lib
RUN echo $ARMONIK_NUGET_REPOS
RUN ls $ARMONIK_NUGET_REPOS
#RUN dotnet nuget add source /app/mock_integration/lib/dotnet5.0
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
RUN ls
WORKDIR /app/publish
RUN ls
ENTRYPOINT ["dotnet"]
