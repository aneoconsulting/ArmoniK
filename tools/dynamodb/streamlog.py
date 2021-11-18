import json
import boto3
import os
from datetime import datetime
import sys

class TimeStamp:
    def __init__(self, ts):
        self.ts = ts
    def __repr__(self):
        s = str(self.ts)
        s = datetime.fromtimestamp(self.ts).strftime("%Y-%d-%m %H:%M:%S")
        return s

def extractJSON(str):
    try:
        return json.loads(str)
    except ValueError as err:
        return None

tag = os.environ['ARMONIK_TAG']
client = boto3.client('logs')

grp = "/aws/lambda/lambda_dynamodb_streams-" + tag
logStreams = client.describe_log_streams(logGroupName=grp)

task_history = dict()
for l in logStreams['logStreams']:
    resp = client.get_log_events(logGroupName=grp, logStreamName=l['logStreamName'])
    for ev in resp['events']:
        jsonev = extractJSON(ev['message'])
        if jsonev == None:
            continue
        #print(jsonev['eventName'])
        if jsonev['eventName'] == 'INSERT':
            data = jsonev['dynamodb']['NewImage']
            task_id = data['task_id']['S']
            task_history[task_id] = dict()
            task_history[task_id]['submitted'] = TimeStamp(int(data['submission_timestamp']['N'])/1000)
            task_history[task_id]['pending'] = list()
            task_history[task_id]['pending'].append(TimeStamp(int(data['submission_timestamp']['N'])/1000))
            task_history[task_id]['processing'] = list()
            task_history[task_id]['finished'] = list()
            task_history[task_id]['agent'] = list()
        elif jsonev['eventName'] == 'MODIFY':
            if jsonev['dynamodb']['NewImage']['task_status']['S'] != jsonev['dynamodb']['OldImage']['task_status']['S']:
                data = jsonev['dynamodb']['NewImage']
                task_id = data['task_id']['S']
                task_status = ''.join((x for x in data['task_status']['S'] if not x.isdigit()))
                ts = TimeStamp(jsonev['dynamodb']['ApproximateCreationDateTime'])
                task_history[task_id][task_status].append(ts)
                if task_status == 'processing':
                    task_history[task_id]['agent'].append(data['task_owner']['S'])


for k, v in task_history.items():
    print(k, v)