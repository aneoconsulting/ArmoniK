import pymongo
import json
from bson.objectid import ObjectId
from datetime import datetime

def print_configs(configs):
    for k, v in configs.items():
        print(f"{k:50}", v)

class TimeStamp:
    def __init__(self, ts):
        self.ts = ts
    def __repr__(self):
        s = str(self.ts)
        s = datetime.fromtimestamp(self.ts).strftime("%Y-%d-%m %H:%M:%S")
        return s

config_file = "generated/Agent_config.json"
with open(config_file) as f:
    configs = json.load(f)

mongodb_con = pymongo.MongoClient(configs['db_endpoint_url'])
state_table = mongodb_con.client[configs['ddb_status_table']]

response = state_table.find()
id_to_taskId = dict()
task_history = dict()
for r in response:
    id_to_taskId[str(r['_id'])] = r['task_id']
    task_history[r['task_id']] = dict()
    task_history[r['task_id']]['submitted'] = TimeStamp(r['submission_timestamp']/1000)
    task_history[r['task_id']]['pending'] = list()
    task_history[r['task_id']]['processing'] = list()
    task_history[r['task_id']]['finished'] = list()
    task_history[r['task_id']]['agent'] = list()
    task_history[r['task_id']]['agent'].append(r['task_owner'])

oplog = mongodb_con.local.oplog.rs


# 'o2._id' : ObjectId('618bf66831cb6bb29d082f76')
response = oplog.find({'op' : 'u', 'o.$set.task_status' : {'$exists': True} }).sort('$natural', pymongo.ASCENDING)
for r in response:
    task_id = id_to_taskId[str(r['o2']['_id'])]
    task_status = ''.join((x for x in r['o']['$set']['task_status'] if not x.isdigit()))
    ts = TimeStamp(r['wall'].timestamp())
    task_history[task_id][task_status].append(ts)

response = oplog.find({'op' : 'i', 'ns' : 'client.' + configs['ddb_status_table'] }).sort('$natural', pymongo.ASCENDING)
for r in response:
    task_id = r['o']['task_id']
    task_status = ''.join((x for x in r['o']['task_status'] if not x.isdigit()))
    ts = TimeStamp(r['wall'].timestamp())
    task_history[task_id][task_status].append(ts)

for k, v in task_history.items():
    print(k, v)