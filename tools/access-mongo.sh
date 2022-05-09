# ACESS to monogo
MPASS=$(kubectl get secret -n armonik mongodb-admin -o jsonpath="{.data.password}" | base64 --decode)
MUSER=$(kubectl get secret -n armonik mongodb-admin -o jsonpath="{.data.username}" | base64 --decode)
kubectl get secret -n armonik mongodb-user-certificates -o jsonpath="{.data.chain\.pem}" | base64 --decode > ./mongodb_chain.pem
MONGO_IP=$(kubectl get svc --selector="service=mongodb" -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
docker run -it -v $(pwd)/mongodb_chain.pem:/chain.pem --rm rtsp/mongosh mongosh --tlsCAFile /chain.pem --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls -u $MUSER -p $MPASS mongodb://$MONGO_IP:27017 #--eval 'db.serverStatus()'
