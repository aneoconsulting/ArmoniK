#!/bin/bash
while true; do
    T1=`date`
    VAL=`kubectl get po | grep 'armonik-agent' | wc -l`
    T2=`date`
    echo "$T1          PODS:[ $VAL ]"
    sleep 60
done