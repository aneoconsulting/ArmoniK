#! /usr/bin/env bash

DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
# Used to provide the correct environment to execute a MongoDB scripts. See `export-all.sh` in the parent directory for an example. You can also read the documentation for more information.
if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo ""
    echo "Usage: $0 <script-name>"
    echo ""
    echo "Available scripts:"
    ls "$DIR/../scripts/"*.js | xargs -n 1 basename | sed 's/\.js//g' | sed 's/^/ - /g'
    exit 1
fi

echo "Executing script: $1"

# Get MongoDB Password
MPASS="$("$DIR/mongodb-password.sh")"
# Get MongoDB Username
MUSER="$("$DIR/mongodb-username.sh")"
# Get MongoDB IPS
MONGO_IPS="$("$DIR/mongodb-ip.sh")"

# Get MongoDB Hosts (IP:PORT)
MONGO_HOSTS="$(echo $MONGO_IPS | sed 's/ /:27017 /g'):27017"

# Generate SSL Certificate
"$DIR/generate-certificate.sh"

# Execute the script on each MongoDB Host (IP:PORT) because the script must be executed on the primary node but we don't know which one is the primary node.
echo "Trying to execute script: $1 on each MongoDB Host (IP:PORT): $MONGO_HOSTS (finding the primary node)"
for MONGO_HOST in $MONGO_HOSTS; do
    echo "Executing script: $1 on $MONGO_HOST"
    docker run -v ./mongodb_chain.pem:/chain.pem -v "$DIR/../../../":/data -v "$DIR/../scripts/node_modules":/root/node_modules --rm rtsp/mongosh mongosh --tls --tlsCAFile=/chain.pem -u "$MUSER" -p "$MPASS" --host "$MONGO_HOST" --authenticationDatabase admin --tlsAllowInvalidHostnames --tlsAllowInvalidCertificates --quiet -f "/data/tools/mongodb/scripts/$1.js"
done

# Delete the SSL Certificate
"$DIR/clean-certificate.sh"
