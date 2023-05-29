# Generate SSL Certificat used to connect to MongoDB
kubectl get secret -n armonik mongodb-user-certificates -o jsonpath="{.data.chain\.pem}" | base64 --decode > $(pwd)/mongodb_chain.pem
