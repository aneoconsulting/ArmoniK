#! /bin/sh

# Get MongoDB Password
kubectl get secret -n armonik mongodb-admin -o jsonpath="{.data.password}" | base64 --decode
