import json
import re

#clean the file with 100 pods
lines_100 = []
keep_100 = []
with open("100p.json",'r') as f_100:
#    #keep only stats lines in the json file
#    """while f:
#        line = f.readline()
#        if line.__contains__("stats"):
#            linegroup.append(line)
#   """
    lines_100=f_100.read().split("\n")
    for line in lines_100:
        if "stats" in line:
            keep_100.append(line)


with open("100p.json",'w') as f_100:
    f_100.write("[\n")
    #write the keeped lines with needed data
    for i in range(0,len(keep_100)-1):
        f_100.write(keep_100[i]+",\n")
    f_100.write(keep_100[len(keep_100)-1]+"\n")
    f_100.write("]")


# #clean the file with 500 pods
# lines_500 = []
# keep_500 = []
# with open("500p.json",'r') as f_500:
#     #keep only stats lines in the json file
#     """while f:
#         line = f.readline()
#         if line.__contains__("stats"):
#             linegroup.append(line)
#     """
#     lines_500=f_500.read().split("\n")
#     for line in lines_500:
#         if "stats" in line:
#             keep_500.append(line_500)


# with open("500p.json",'w') as f_500:
#     f_500.write("[\n")
#     #write the keeped lines with needed data
#     for i in range(0,len(keep_500)-1):
#         f_500.write(keep_500[i]+",\n")
#     f_500.write(keep_500[len(keep_500)-1]+"\n")
#     f_500.write("]")


# #clean the file with 1000 pods
# lines_1000 = []
# keep_1000 = []
# with open("1000p.json",'r') as f_1000:
#     #keep only stats lines in the json file
#     """while f:
#         line = f.readline()
#         if line.__contains__("stats"):
#             linegroup.append(line)
#     """
#     lines_1000=f_1000.read().split("\n")
#     for line in lines_1000:
#         if "stats" in line:
#             keep_1000.append(line)


# with open("1000p.json",'w') as f_1000:
#     f_1000.write("[\n")
#     #write the keeped lines with needed data
#     for i in range(0,len(keep_1000)-1):
#         f_1000.write(keep_1000[i]+",\n")
#     f_1000.write(keep_1000[len(keep_1000)-1]+"\n")
#     f_1000.write("]")

# #clean the file with 1000 pods
# lines_10000 = []
# keep_10000 = []
# with open("10000p.json",'r') as f_10000:
#     #keep only stats lines in the json file
#     """while f:
#         line = f.readline()
#         if line.__contains__("stats"):
#             linegroup.append(line)
#     """
#     lines_10000=f_10000.read().split("\n")
#     for line in lines_10000:
#         if "stats" in line:
#             keep_10000.append(line)


# with open("10000p.json",'w') as f_10000:
#     f_10000.write("[\n")
#     #write the keeped lines with needed data
#     for i in range(0,len(keep_10000)-1):
#         f_10000.write(keep_10000[i]+",\n")
#     f_10000.write(keep_10000[len(keep_10000)-1]+"\n")
#     f_10000.write("]")



#f.truncate()

#f.write("[")
#for l in linegroup:
#    f.write(l)
#f.write("]")

"""
def clean_json_file(file):
    #clean the file with 100 pods
    lines = []
    keep = []
    with open(file,'r') as f:
        #keep only stats lines in the json file
        lines=f.read().split("\n")
        for line in lines:
            if "stats" in line:
                keep.append(line)


    with open(file,'w') as f:
        f.write("[\n")
        #write the keeped lines with needed data
        for i in range(0,len(keep)-1):
            f.write(keep[i]+",\n")
        f.write(keep[len(keep)-1]+"\n")
        f.write("]")

clean_json_file("100p.json")
"""