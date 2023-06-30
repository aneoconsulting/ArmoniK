#! /usr/bin/env python3

import json
import re
from jsonmerge import merge

result = []
with open("../../../../../versions.tfvars.json", "r") as versions:
    result.append(json.load(versions))
with open("../stats/test_env.json", "r") as test_env:
    result.append(json.load(test_env))
with open("../stats/5k.json", "r") as stats:
    result.append(json.load(stats))
with open("result_4agg_1h.json", "w") as r:

    dict_json = [merge(result[0], result[1]), result[2]]
    json.dump(dict_json, r)
