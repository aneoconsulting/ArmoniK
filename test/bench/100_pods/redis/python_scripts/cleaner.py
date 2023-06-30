#! /usr/bin/env python3

import json
import re


def clean_file(file):
    lines = []
    keep_stats = []
    keep_tput = []
    keep_options = []

    # read the output file with no needed data
    with open(file, 'r') as f:
        # keep only stats lines in the json file
        lines = f.read().split("\n")
        for line in lines:
            if not line: continue
            # print(line)
            jline = json.loads(line)
            if "stats" in jline:
                keep_stats.append(jline["stats"])
                keep_options.append(jline["benchOptions"])
            if "sessionThroughput" in jline:
                keep_tput.append(jline["sessionThroughput"])
    dic_json = [{"Test": "bench"} | stats | options | {"throughput": tput, "nb_pods": 100} for stats, tput, options in
                zip(keep_stats, keep_tput, keep_options)]

    # write a clean json file with needed data
    with open(file, 'w') as f:
        json.dump(dic_json, f)


# clean the stats file
file = "../stats/1k.json"
clean_file(file)
file = "../stats/5k.json"
clean_file(file)
