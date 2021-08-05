

To compile with HTCGridSDK
    - make BUILD_TYPE=Release


Please bring your agent config file into folder HtcCommon :

The Agent_config.json file looks like following :
{
    "region": "$REGION",
    "sqs_endpoint": "https://sqs.$REGION.amazonaws.com",
    "sqs_queue": "htc_task_queue-$TAG",
    "sqs_dlq": "htc_task_queue_dlq-$TAG",

    ....

    "public_api_gateway_url": "https://ofz8rihsjh.execute-api.eu-west-1.amazonaws.com/v1",

    ...
}


To run the Htc.Mock.CloudGridSample do :
    dotnet run `[MyAgent_Config.json`] # Default will be ./agent_config.json