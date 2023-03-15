import json
import re

def clean_file(file):
    lines=[]
    keep_stats=[]
    keep_tput=[]
    keep_options=[]
    #read the output file with no needed data
    with open(file,'r') as f:
        #keep only stats lines in the json file
        lines = f.read().split("\n")
        for line in lines:
            if not line: continue
            print(line)
            jline=json.loads(line)
            if "stats" in jline:
                keep_stats.append(jline["stats"])
                keep_options.append(jline["benchOptions"])
            if "sessionThroughput" in jline:
                keep_tput.append(jline["sessionThroughput"])
    dic_json=[stats | options | {"throughput" : tput, "storage":"S3", "nb_pods":100 }  for stats,tput,options in zip(keep_stats,keep_tput,keep_options)]

    #write a clean json file with needed data
    with open(file,'w') as f:
        json.dump(dic_json, f)
        #add the first line of a Json list
        # f.write("[\n")
        # #write the keep_statsed lines with needed data
        # for i in range(0,len(keep_stats)-1):
        #     f.write(keep_stats[i]+',"throughput":'+keep_tput[i]+',"bench options":'+keep_options[i]+'"storage":"S3"'+'"nb_pods":100'+"},\n")
        # f.write(keep_stats[len(keep_stats)-1]+',"throughput":'+keep_tput[len(keep_tput)-1]+',"bench options":'+keep_options[len(keep_options)-1]+'"storage":"S3"'+'"nb_pods":100'+"}\n")
        # #close the json list
        # f.write("]")


#clean the file with 100 pods
file = "10k_0.11.4.json"
clean_file(file)