#! /bin/sh

# Get MongoDB IP
kubectl get svc --selector="service=mongodb" -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true
