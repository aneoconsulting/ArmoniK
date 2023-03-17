import json
from pytimeparse import parse
import matplotlib.pyplot as plt
import numpy as np

#function to calculate mean
def mean(dataset):
    return sum(dataset)/len(dataset)

#function to calculate the median
def median(dataset):
    data = sorted(dataset)
    index = len(data) // 2
    
    # If the dataset is odd  
    if len(dataset) % 2 != 0:
        return data[index]
    
    # If the dataset is even
    return (data[index - 1] + data[index]) / 2

#function to read file and stock the data in lists
def f_reader(file):
    with open(file) as my_bench_file:
        data= my_bench_file.read()

    runs = json.loads(data)
    nbtasks = []
    time = []
    exec_time = []
    sub_time = []
    retrv_time = []
    throughput = []
    d_parallel = []

    for run in runs:
        if(run["nb_pods"]==100):
            nbtasks.append(run["TotalTasks"])
            time.append(float(parse(run["ElapsedTime"])))
            exec_time.append(float(parse(run["TasksExecutionTime"])))
            sub_time.append(float(parse(run["SubmissionTime"])))
            retrv_time.append(float(parse(run["ResultRetrievingTime"])))
            throughput.append(float(run["throughput"]))
            d_parallel.append(run["DegreeOfParallelism"])


    return nbtasks, time, exec_time, sub_time, retrv_time, throughput, d_parallel

######################################################################
#                      TREAT 10K TASKS 100 PODS                      #
######################################################################

#open 10k tasks on 100 pods file
# file = 'data/data_10k_100p_0.11.4.json'
file = '10k.json'

#store the runs stats
nbtasks_10k_100p = []
time_10k_100p = []
exec_time_10k_100p = []
sub_time_10k_100p = []
retrv_time_10k_100p = []
throughput_10k_100p = []
d_parallel_10k_100p = []

nbtasks_10k_100p, time_10k_100p, exec_time_10k_100p, sub_time_10k_100p, retrv_time_10k_100p, throughput_10k_100p, d_parallel_10k_100p = f_reader(file)

#calculte the mean times of the runs
mean_time_10k_100=mean(time_10k_100p)
mean_exec_time_10k_100p=mean(exec_time_10k_100p)
mean_sub_time_10k_100=mean(sub_time_10k_100p)
mean_retrv_time_10k_100=mean(retrv_time_10k_100p)
mean_throughput_10k_100=mean(throughput_10k_100p)

#print the perf stats
print('Degree of parallelism of retrieving time is : '+ str(d_parallel_10k_100p[0]))
print('mean total time for treatement of 10K tasks on 100 pods is : '+ str(mean_time_10k_100) +' s')
print('mean time of the execution of 10K tasks on 100 pods is : '+ str(mean_exec_time_10k_100p) +' s')
print('mean time of the submission of 10K tasks on 100 pods is : '+ str(mean_sub_time_10k_100) +' s')
print('mean time of the retrieving of 10K tasks on 100 pods is : '+ str(mean_retrv_time_10k_100) +' s')
print('mean throughput for 10K tasks on 100 pods is : '+ str(mean_throughput_10k_100)+" tasks/s \n")

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