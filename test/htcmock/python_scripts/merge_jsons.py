#! /usr/bin/env python3

import json
import re
from jsonmerge import merge

with open("../../../versions.tfvars.json", "r") as versions:
    infra = json.load(versions)
with open("../stats/test_env.json", "r") as test_env:
    env = json.load(test_env)
with open("../stats/5k.json", "r") as stats:
    result_5k = json.load(stats)
with open("../stats/results.json", "w") as r:

    dict_json = [merge(infra, env), result_5k]
    json.dump(dict_json, r)
