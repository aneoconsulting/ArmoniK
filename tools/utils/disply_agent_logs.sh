#!/bin/bash
for i in $(kubectl get po -n armonik | grep ^compute-plane- | cut -d' ' -f1)
do
echo
echo -------------------------------------------------------------
echo $i
echo -------------------------------------------------------------
echo -------------------------------------------------------------
#kubectl logs $i -n armonik -c compute-0 | grep -E "Htc.Mock|Execute"
kubectl logs $i -n armonik -c compute-0 --tail=30
echo -------------------------------------------------------------
echo -------------------------------------------------------------
kubectl logs $i -n armonik -c polling-agent --tail=30
echo -------------------------------------------------------------
echo -------------------------------------------------------------
echo
done
