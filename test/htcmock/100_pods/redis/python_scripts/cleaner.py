#! /usr/bin/env python3

import json
import re


def clean_file(file):
    lines = []
    keep_stats = []
    keep_config = []
    keep_tput = []

    # read the output file with no needed data
    with open(file, 'r') as f:
        # keep only stats lines in the json file
        lines = f.read().split("\n")[10:]
        for line in lines:
            if not line: continue
            # print(line)
            jline = json.loads(line)
            if "configuration" in jline:
                keep_config.append(jline)
            if "time" in jline:
                keep_stats.append(jline)
            if "throughput" in jline:
                keep_tput.append(jline)
    dic_json = [{"Test": "htcmock"} | stats | {"configuration": conf, "throughput": tput, "nb_pods": 100} for
                stats, conf, tput in zip(keep_stats, keep_config, keep_tput)]
    print(keep_stats)
    # write a clean json file with needed data
    with open(file, 'w') as f:
        json.dump(dic_json, f)


# clean the stats file
# file = "../stats/4_agg/1k.json"
# clean_file(file)
file = "../stats/4_agg/5k.json"
clean_file(file)
# file = "../stats/4_agg/10k.json"
# clean_file(file)
# file = "out.json"
# clean_file(file)
