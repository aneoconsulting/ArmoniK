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


#open p100 file
with open('100p.json') as my_bench_file:
    data_100 = my_bench_file.read()

print(type(data_100))
runs = json.loads(data_100)
print(runs)
print(type(runs))

#store data for 100 pods
nbtasks_100p = []
time_100p = []
pods_100p = []

for run in runs:
    nbtasks_100p.append(run["stats"]["TotalTasks"])
    time_100p.append(float(parse(run["stats"]["ElapsedTime"])))
    #pods.append(run["pods"])
    pods_100p.append(100)

print(nbtasks_100p)
print(time_100p)
print(pods_100p)

mean_time_100=mean(time_100p)
median_time_100=median(time_100p)
print('mean time for 100 pods is : '+ str(mean_time_100) +' s')
print('median time for 100 pods is : '+ str(median_time_100) +' s')



#plot graph

#plt.plot(nbtasks_100p,time_100p,color="green")

#plt.xlabel('tasks')
#plt.ylabel('time(ms)')
#plt.title('Bench test with ArmoniK(2.11.0) on 100 pods')

#plt.show()
#plt.savefig("graphs/100pods.png")


"""
#open p500 file
with open('500p.json') as my_bench_file:
    data_500 = my_bench_file.read()

print(type(data_500))
runs = json.loads(data_500)
print(runs)
print(type(runs))

#store data for 500p
nbtasks_500p = []
time_500p = []
pods_500p = []

for run in runs:
    nbtasks_500p.append(run["stats"]["TotalTasks"])
    time_500p.append(float(parse(run["stats"]["ElapsedTime"])))
    #pods.append(run["pods"])
    pods_500p.append(500)

print(nbtasks_500p)
print(time_500p)
print(pods_500p)

#open p1000 file
with open('1000p.json') as my_bench_file:
    data_1000 = my_bench_file.read()

print(type(data_1000))
runs = json.loads(data_1000)
print(runs)
print(type(runs))

#store data for 1000p
nbtasks_1000p = []
time_1000p = []
pods_1000p = []

for run in runs:
    nbtasks_1000p.append(run["stats"]["TotalTasks"])
    time_1000p.append(float(parse(run["stats"]["ElapsedTime"])))
    #pods.append(run["pods"])
    pods_1000p.append(1000)

print(nbtasks_1000p)
print(time_1000p)
print(pods_1000p)

#open p10000 file
with open('10000p.json') as my_bench_file:
    data_10000 = my_bench_file.read()

print(type(data_10000))
runs = json.loads(data_10000)
print(runs)
print(type(runs))

#store data for 1000p
nbtasks_10000p = []
time_10000p = []
pods_10000p = []

for run in runs:
    nbtasks_10000p.append(run["stats"]["TotalTasks"])
    time_10000p.append(float(parse(run["stats"]["ElapsedTime"])))
    #pods.append(run["pods"])
    pods_10000p.append(10000)

print(nbtasks_10000p)
print(time_10000p)
print(pods_10000p)
"""

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
