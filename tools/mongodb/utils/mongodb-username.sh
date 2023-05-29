# Get MongoDB Username
kubectl get secret -n armonik mongodb-admin -o jsonpath="{.data.username}" | base64 --decode
