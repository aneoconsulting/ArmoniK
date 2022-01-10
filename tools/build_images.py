import json
import os
import subprocess
import sys

def findTag(imgs):
    tags = []
    for i in imgs:
        if i['Repository'].startswith('dockerhubaneo') and i['Tag'].startswith('dev'):
            tags.append(i['Tag'])
    if len(tags) > 0:
        tag = sorted(tags).pop()
        return tag
    else:
        return 'dev-1000'

def incrTag(tag):
    s = tag.split('-')
    return s[0] + '-' + str(int(s[1]) + 1)

imgs = [json.loads(r) for r in os.popen('docker image ls --format="{{json .}}"').readlines()]

tag = findTag(imgs)
tag = incrTag(tag)
print(tag)

processes = []
processes.append(subprocess.Popen(f'docker build -t dockerhubaneo/armonik_control:{tag} -f src/Control/src/Dockerfile .', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE))
processes.append(subprocess.Popen(f'docker build -t dockerhubaneo/armonik_pollingagent:{tag} -f src/Compute/PollingAgent/src/Dockerfile .', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE))
#processes.append(subprocess.Popen(f'docker build -t dockerhubaneo/armonik_worker_htcmock:{tag} -f Samples/HtcMock/GridWorker/src/Dockerfile .', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE))
processes.append(subprocess.Popen(f'docker build -t dockerhubaneo/armonik_worker_dll:{tag} -f DevelopmentKit/csharp/WorkerApi/ArmoniK.DevelopmentKit.WorkerApi/Dockerfile .', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE))

for p in processes:
    print(p.communicate()[0].decode('utf-8'))

if any([p.returncode for p in processes]):
    print('error while building')
    for p in processes:
        if p.returncode:
            print(p.communicate()[1].decode('utf-8'))
    sys.exit(1)

print(tag)