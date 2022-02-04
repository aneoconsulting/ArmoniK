pushd $(dirname "${BASH_SOURCE[0]}")
pushd $(pwd -P)/../../armonik
ARMONIK_PATH=$(pwd -P)
# Armonik namespace in the Kubernetes
export ARMONIK_NAMESPACE=armonik

# Directory path of the Redis certificates
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_PATH/../security/certificates
export ARMONIK_REDIS_CREDENTIALS_DIRECTORY=$ARMONIK_PATH/../security/credentials

# Name of Redis secret
export ARMONIK_REDIS_SECRET_NAME=redis-storage-secret

# Directory path of the certificates for external Redis
export ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_PATH/../security/certificates
export ARMONIK_EXTERNAL_REDIS_CREDENTIALS_DIRECTORY=$ARMONIK_PATH/../security/credentials

# Name of secret of external Redis
export ARMONIK_EXTERNAL_REDIS_SECRET_NAME=external-redis-storage-secret

# Directory path of the ActiveMQ credentials
export ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY=$ARMONIK_PATH/../security/credentials
export ARMONIK_ACTIVEMQ_CERTIFICATES_DIRECTORY=$ARMONIK_PATH/../security/certificates

# Name of ActiveMQ secret
export ARMONIK_ACTIVEMQ_SECRET_NAME=activemq-storage-secret

# Directory path of the MongoDB credentials
export ARMONIK_MONGODB_CREDENTIALS_DIRECTORY=$ARMONIK_PATH/../security/credentials
export ARMONIK_MONGODB_CERTIFICATES_DIRECTORY=$ARMONIK_PATH/../security/certificates

# Name of MongoDB secret
export ARMONIK_MONGODB_SECRET_NAME=mongodb-storage-secret
popd
popd
env | grep --color=always ARMONIK