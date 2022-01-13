import json

def lambda_handler(event, context):
    for record in event['Records']:
        print(json.dumps(record))
    return