FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as base
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim as build

RUN mkdir -p /app
WORKDIR "/app"

COPY ./mock_computation_image /app/mock_computation_image

WORKDIR "/app/mock_computation_image/src"
RUN dotnet restore "mock_computation_image/mock_computation_image.csproj"

WORKDIR "/app/mock_computation_image/src/mock_computation_image"
RUN mkdir -p ./lib/
COPY ./HttpApi.dll ./lib/
COPY ./HTCGridAPI.dll ./lib/
COPY ./ClientTask.cs ./
RUN dotnet build "mock_computation_image.csproj" --configuration Release --output /app/build

FROM build AS publish
RUN dotnet publish "mock_computation_image.csproj" \
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
