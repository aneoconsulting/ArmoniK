import json
import boto3
import os
from datetime import datetime
import sys
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import argparse

class TimeStamp:
    def __init__(self, ts):
        self.ts = ts
    def __repr__(self):
        if self.ts == None:
            return ''
        s = str(self.ts)
        s = datetime.fromtimestamp(self.ts).strftime("%Y-%d-%m %H:%M:%S")
        return s
    def _is_valid_operand(self, other):
        return hasattr(other, "ts")
    def __eq__(self, other):
        if not self._is_valid_operand(other):
            return NotImplemented
        return self.ts == other.ts
    def __lt__(self, other):
        if not self._is_valid_operand(other):
            return NotImplemented
        return self.ts < other.ts

def initTaskDict(d, task_id):
    d[task_id] = dict()
    d[task_id]['agent'] = list()

def extractJSON(str):
    try:
        return json.loads(str)
    except ValueError as err:
        return None


parser = argparse.ArgumentParser(description="Process Dynamodb Stream events related to Armonik execution")
parser.add_argument("lts", help="Datetime for log selection (start)", type=str)
parser.add_argument("lte", help="Datetime for log selection (end)", type=str)
parser.add_argument("ots", help="Datetime for output selection (start)", type=str)
parser.add_argument("ote", help="Datetime for output selection (end)", type=str)
parser.add_argument("-o", "--output", dest="output", help="Output file.", type=str, default="results.pdf")
args = parser.parse_args()


lts = int(round(datetime.strptime(args.lts, "%Y-%m-%d_%H:%M").timestamp())) * 1000
lte = int(round(datetime.strptime(args.lte, "%Y-%m-%d_%H:%M").timestamp())) * 1000
ots = int(round(datetime.strptime(args.ots, "%Y-%m-%d_%H:%M").timestamp()))
ote = int(round(datetime.strptime(args.ote, "%Y-%m-%d_%H:%M").timestamp()))

tag = os.environ['ARMONIK_TAG']
client = boto3.client('logs')

grp = "/aws/lambda/lambda_dynamodb_streams-" + tag
logStreams = client.describe_log_streams(logGroupName=grp)

task_history = dict()
for l in logStreams['logStreams']:
    nextToken = ""
    while nextToken != None:
        if nextToken == "":
            resp = client.get_log_events(logGroupName=grp, logStreamName=l['logStreamName'], startFromHead=True, startTime=lts, endTime=lte)
        else:
            resp = client.get_log_events(logGroupName=grp, logStreamName=l['logStreamName'], startFromHead=True, startTime=lts, endTime=lte, nextToken = nextToken)
        for ev in resp['events']:
            jsonev = extractJSON(ev['message'])
            if jsonev == None:
                continue
            #print(jsonev['eventName'])
            if jsonev['eventName'] == 'INSERT':
                data = jsonev['dynamodb']['NewImage']
                task_id = data['task_id']['S']
                if task_id not in task_history:
                    initTaskDict(task_history, task_id)
                task_history[task_id]['submitted'] = TimeStamp(int(data['submission_timestamp']['N'])/1000)
                ts = TimeStamp(int(data['submission_timestamp']['N'])/1000)
                task_history[task_id]['pending'] = min(task_history[task_id].get('pending', ts), ts)
            elif jsonev['eventName'] == 'MODIFY':
                if jsonev['dynamodb']['NewImage']['task_status']['S'] != jsonev['dynamodb']['OldImage']['task_status']['S']:
                    data = jsonev['dynamodb']['NewImage']
                    task_id = data['task_id']['S']
                    if task_id not in task_history:
                        initTaskDict(task_history, task_id)
                    task_status = ''.join((x for x in data['task_status']['S'] if not x.isdigit()))
                    ts = TimeStamp(jsonev['dynamodb']['ApproximateCreationDateTime'])
                    if task_status == 'processing':
                        task_history[task_id]['agent'].append(data['task_owner']['S'])
                    if task_status == 'finished':
                        task_history[task_id][task_status] = max(task_history[task_id].get(task_status, ts), ts)
                    else:
                        task_history[task_id][task_status] = min(task_history[task_id].get(task_status, ts), ts)
        if 'nextForwardToken' in resp:
            token = resp['nextForwardToken']
            if token != nextToken:
                nextToken = token
            else:
                nextToken = None
        else:
            nextToken = None


count_pending = dict()
count_submitted = dict()
count_processing = dict()
count_finished = dict()
nbtasks = 0

end = int((ote - ots)/6)+1
for k, v in task_history.items():
    if v['submitted'] == None:
        continue
    if v['submitted'].ts > ots and v['submitted'].ts < ote:
        t_submitted = int((v['submitted'].ts - ots)/6)
        t_pending = int((v['pending'].ts - ots)/6)
        t_processing = int((v['processing'].ts - ots)/6)
        t_finished = int((v.get('finished', TimeStamp(end*6)).ts - ots)/6)
        nbtasks += 1
        print(k, v)
        for x in range(t_submitted, end):
            count_submitted[x] = count_submitted.get(x, 0) + 1
        for x in range(t_pending, t_processing):
            count_pending[x] = count_pending.get(x, 0) + 1
        for x in range(t_processing, t_finished):
            count_processing[x] = count_processing.get(x, 0) + 1
        for x in range(t_finished, end):
            count_finished[x] = count_finished.get(x, 0) + 1


count_submitted = sorted(count_submitted.items(), key=lambda x: x[0])
count_pending = sorted(count_pending.items(), key=lambda x: x[0])
count_processing = sorted(count_processing.items(), key=lambda x: x[0])
count_finished = sorted(count_finished.items(), key=lambda x: x[0])

print("nbtasks :", nbtasks)

fig = plt.figure()
ax = fig.gca()
ax.plot([x[0]/10 for x in count_submitted], [x[1] for x in count_submitted], label = 'submitted')
ax.plot([x[0]/10 for x in count_pending], [x[1] for x in count_pending], label = 'pending')
ax.plot([x[0]/10 for x in count_processing], [x[1] for x in count_processing], label = 'processing')
ax.plot([x[0]/10 for x in count_finished], [x[1] for x in count_finished], label = 'finished')
fig.legend()
plt.ylabel("#Task")
plt.xlabel("Time (min)")
fig.savefig(args.output, bbox_inches = "tight", metadata = {'CreationDate': None})
plt.close()