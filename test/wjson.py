import json
from pytimeparse import parse
import matplotlib.pyplot as plt
import numpy as np

#fonction calcul'e la moyenne
def mean(dataset):
    return sum(dataset)/len(dataset)

#fonction qui calcule la mediane
def median(dataset):
    data = sorted(dataset)
    index = len(data) // 2
    
    # If the dataset is odd  
    if len(dataset) % 2 != 0:
        return data[index]
    
    # If the dataset is even
    return (data[index - 1] + data[index]) / 2

######################################################################
#                      TREAT 10K TASKS 100 PODS                      #
######################################################################

#open 10k tasks on 100 pods file
# with open('data/data_10k_100p.json') as my_bench_file:
#     data_10k_100 = my_bench_file.read()

# print(type(data_10k_100))
# runs = json.loads(data_10k_100)
# print(runs)
# print(type(runs))

# #store data for 10k tasks on 100 pods
# nbtasks_10k_100p = []
# time_10k_100p = []
# pods_10k_100p = []

# for run in runs:
#     nbtasks_10k_100p.append(run["stats"]["TotalTasks"])
#     time_10k_100p.append(float(parse(run["stats"]["ElapsedTime"])))
#     pods_10k_100p.append(100)

# print(nbtasks_10k_100p)
# print(time_10k_100p)
# print(pods_10k_100p)

# mean_time_10k_100=mean(time_10k_100p)
# median_time_10k_100=median(time_10k_100p)
# print('mean time for 10K tasks on 100 pods is : '+ str(mean_time_10k_100) +' s')
# print('median time for 10K tasks on 100 pods is : '+ str(median_time_10k_100) +' s')

######################################################################
#                      TREAT 100K TASKS 100 PODS                     #
######################################################################

#open 100k tasks on 100 pods file
with open('data/data_100k_100p.json') as my_bench_file:
    data_100k_100 = my_bench_file.read()

print(type(data_100k_100))
runs = json.loads(data_100k_100)
print(runs)
print(type(runs))

#store data for 10k tasks on 100 pods
nbtasks_100k_100p = []
time_100k_100p = []
pods_100k_100p = []

for run in runs:
    nbtasks_100k_100p.append(run["stats"]["TotalTasks"])
    time_100k_100p.append(float(parse(run["stats"]["ElapsedTime"])))
    pods_100k_100p.append(100)

print(nbtasks_100k_100p)
print(time_100k_100p)
print(pods_100k_100p)

mean_time_100k_100p=mean(time_100k_100p)
median_time_100k_100p=median(time_100k_100p)
print('mean time for 100K tasks on 100 pods is : '+ str(mean_time_100k_100p) +' s')
print('median time for 100K tasks in 100 pods is : '+ str(median_time_100k_100p) +' s')


###############################################################
#                           PLOT                              #
###############################################################

#plot graph

#plt.plot(nbtasks_500p,time_500p,color="blue")
#plt.hist(pods_100p[0],mean_time_100)
#plt.xlabel('pods')
#plt.ylabel('time(s)')
#plt.title('Bench test with ArmoniK(2.11.0) on 100p with '+nbtasks_100p[0]+' tasks')

#plt.show()
#plt.savefig("graphs/500pods.png")

#plt.figure(figsize=(5, 2.7), layout='constrained')
#plt.plot(pods_100p,time_100p,color='r', label='Bench on 100 pods')
#plt.plot(pods_500p,time_500p,color='g', label='Bench on 500 pods')
#plt.plot(pods_1000p,time_1000p,color='r', label='Bench on 1000 pods')
#plt.plot(pods_10000p,time_10000p,color='g', label='Bench on 10000 pods')
#plt.xlabel('pods')
#plt.ylabel('time(s)')
#plt.yticks(np.linspace(0,60,5,endpoint=True))
#plt.title('Bench test : run 500000 with ArmoniK(2.11.0) on 100p')
#plt.legend()
#plt.savefig("graphs/100p.png")
