FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build

RUN mkdir -p /app
WORKDIR /app

RUN mkdir -p ./lib/dotnet5.0
COPY ./dist/dotnet5.0/HTCGridAPI.1.0.0.nupkg ./lib/dotnet5.0
COPY ./dist/dotnet5.0/HttpApi.1.0.0.nupkg ./lib/dotnet5.0
COPY ./examples/workloads/dotnet5.0/mock_subtasking/mock_subtasking/src ./src
COPY ./examples/workloads/dotnet5.0/mock_subtasking/mock_subtasking/test ./test
RUN ls
WORKDIR /app/src/mock_subtasking
RUN ls
RUN dotnet nuget add source /app/lib/dotnet5.0
RUN dotnet restore "mock_subtasking.csproj"
RUN dotnet build "mock_subtasking.csproj" --configuration Release --output /app/build

FROM build AS publish
RUN dotnet publish "mock_subtasking.csproj" \
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
