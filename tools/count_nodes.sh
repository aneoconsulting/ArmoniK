#!/bin/bash
while true; do 
    T1=`date`
    VAL=`kubectl get nodes | grep Ready | wc -l`
    T2=`date`
    echo "$T1          NODES:[ $VAL ]"
    sleep 60
done

