
# Args: <script-name>
if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo ""
    echo "Usage: $0 <script-name>"
    echo ""
    echo "Available scripts:"
    ls $(pwd)/tools/mongodb/scripts/*.js | xargs -n 1 basename | sed 's/\.js//g' | sed 's/^/ - /g'
    exit 1
fi

echo "Executing script: $1"

DEST=$(pwd)
# Get MongoDB Password
MPASS=$($DEST/tools/mongodb/utils/mongodb-password.sh)
# Get MongoDB Username
MUSER=$($DEST/tools/mongodb/utils/mongodb-username.sh)
# Get MongoDB IP
MONGO_IP=$($DEST/tools/mongodb/utils/mongodb-ip.sh)

# Generate SSL Certificat
$DEST/tools/mongodb/utils/generate-certificat.sh

# Export all collections from database
docker run -v $DEST/mongodb_chain.pem:/chain.pem -v $DEST:/data -v $DEST/tools/mongodb/scripts/node_modules:/root/node_modules --rm rtsp/mongosh mongosh --tls --tlsCAFile=/chain.pem -u $MUSER -p $MPASS --authenticationDatabase admin --host=$MONGO_IP:27017  --tlsAllowInvalidHostnames --tlsAllowInvalidCertificates --quiet /data/tools/mongodb/scripts/$1.js

$DEST/tools/mongodb/utils/clean-certificat.sh
