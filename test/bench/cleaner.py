import json
import re

def clean_file(file):
    lines=[]
    keep_stats=[]
    keep_tput=[]
    #read the output file with no needed data
    with open(file,'r') as f:
        #keep only stats lines in the json file
        lines = f.read().split("\n")
        for line in lines:
            if "executions stats" in line:
                keep_stats.append(line[:-1])
            if "Throughput for session" in line:
                keep_tput.append(line)
    #write a clean json file with needed data
    with open(file,'w') as f:
        #add the first line of a Json list
        f.write("[\n")
        #write the keep_statsed lines with needed data
        for i in range(0,len(keep_stats)-1):
            f.write(keep_stats[i]+',"throughput":'+keep_tput[i]+"},\n")
        f.write(keep_stats[len(keep_stats)-1]+',"throughput":'+keep_tput[len(keep_tput)-1]+"}\n")
        #close the json list
        f.write("]")


#clean the file with 100 pods
file = "10k_1000p.json"
clean_file(file)
