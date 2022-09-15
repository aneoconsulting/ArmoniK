#!/bin/bash
# check if -h or --help was passed
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 [--dest=string]"
    echo ""

    echo "This script will export data from collections TaskData, SessionData and Result from database of ArmoniK"
    echo "Data will be saved to Session.json, TaskData.json and Result.json in the wanted destination (default is current directory)."
    exit 1
fi

# Get the destination from the argument list (could be anywhere in the list)
DEST=$(echo "$@" | grep -oe '--dest=.*' | sed 's/--dest=//')

# Set to pwd if no destination was passed
if [ -z "$DEST" ]; then
    DEST="$(pwd)"
fi

# Create the destination directory if it doesn't exist
mkdir -p $DEST

# Get MongoDB Password
MPASS=$(kubectl get secret -n armonik mongodb-admin -o jsonpath="{.data.password}" | base64 --decode)
# Get MongoDB Username
MUSER=$(kubectl get secret -n armonik mongodb-admin -o jsonpath="{.data.username}" | base64 --decode)
# Get SSL Certificat from MongoDB
kubectl get secret -n armonik mongodb-user-certificates -o jsonpath="{.data.chain\.pem}" | base64 --decode > ./mongodb_chain.pem
# Get MongoDB IP
MONGO_IP=$(kubectl get svc --selector="service=mongodb" -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)

# Export SessionData collection from database 
docker run -it -v $(pwd)/mongodb_chain.pem:/chain.pem -v $DEST:/data --rm rtsp/mongosh mongoexport --collection=SessionData --db=database  --ssl --sslCAFile=/chain.pem --tlsInsecure -u $MUSER -p $MPASS --authenticationDatabase admin --host=$MONGO_IP:27017 --out=/data/SessionData.json --jsonArray

# Export TaskData collection from database
docker run -it -v $(pwd)/mongodb_chain.pem:/chain.pem -v $DEST:/data --rm rtsp/mongosh mongoexport --collection=TaskData --db=database  --ssl --sslCAFile=/chain.pem --tlsInsecure -u $MUSER -p $MPASS --authenticationDatabase admin --host=$MONGO_IP:27017 --out=/data/TaskData.json --jsonArray

# Export Result collection from database
docker run -it -v $(pwd)/mongodb_chain.pem:/chain.pem -v $DEST:/data --rm rtsp/mongosh mongoexport --collection=Result --db=database  --ssl --sslCAFile=/chain.pem --tlsInsecure -u $MUSER -p $MPASS --authenticationDatabase admin --host=$MONGO_IP:27017 --out=/data/Result.json --jsonArray

# Delete the SSL Certificat
rm ./mongodb_chain.pem