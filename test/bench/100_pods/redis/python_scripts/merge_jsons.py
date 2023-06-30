#! /usr/bin/env python3

import json
import re
from jsonmerge import merge

result = []
with open("../../../../../versions.tfvars.json", "r") as versions:
    result.append(json.load(versions))
with open("../stats/test_env.json", "r") as test_env:
    result.append(json.load(test_env))
with open("../stats/1k.json", "r") as stats:
    result.append(json.load(stats))
# merged=merge(result[0],result[1])
# print(merged)
# merged=merge(merged,result[2])
# print(merged)

with open("../stats/5k.json", "r") as stats:
    result2 = json.load(stats)
# print(merged)
with open("results.json", "w") as r:
    # json.dump(result,r)
    dict_json = [merge(result[0], result[1]), result[2], result2]
    json.dump(dict_json, r)
