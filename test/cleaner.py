import json
import re

def clean_file(file):
    lines=[]
    keep=[]
    #read the output file with no needed data
    with open(file,'r') as f:
        #keep only stats lines in the json file
        lines = f.read().split("\n")
        for line in lines:
            if "stats" in line:
                keep.append(line)
    #write a clean json file with needed data
    with open(file,'w') as f:
        #add the first line of a Json list
        f.write("[\n")
        #write the keeped lines with needed data
        for i in range(0,len(keep)-1):
            f.write(keep[i]+",\n")
        f.write(keep[len(keep)-1]+"\n")
        #close the json list
        f.write("]")


#clean the file with 100 pods
file = "10k_100p.json"
clean_file(file)
