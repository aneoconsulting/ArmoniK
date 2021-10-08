FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build


RUN apt-get update ; apt-get install -y build-essential
WORKDIR /app/mock_integration
RUN mkdir -p ./lib/dotnet5.0
COPY ./dist/dotnet5.0/HTCGridAPI.1.0.0.nupkg ./lib/dotnet5.0
COPY ./dist/dotnet5.0/HttpApi.1.0.0.nupkg ./lib/dotnet5.0
#COPY ./examples/csharp/ClientTask.cs ./
COPY ./examples/mock_integration ./
RUN ls ./lib
RUN ls -la nuget.config
ENV ARMONIK_NUGET_REPOS=/app/mock_integration/lib/dotnet5.0
RUN echo $ARMONIK_NUGET_REPOS
RUN ls $ARMONIK_NUGET_REPOS
#RUN dotnet nuget add source /app/mock_integration/lib/dotnet5.0
WORKDIR /app/mock_integration/Client
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
RUN mkdir -p ~/.nuget/NuGet
COPY ./examples/mock_integration/Client/NuGet.Config ~/.nuget/NuGet/
COPY ./examples/mock_integration/Client/commands.txt /app/publish
ENTRYPOINT ["dotnet"]
