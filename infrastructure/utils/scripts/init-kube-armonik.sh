#!/bin/bash
set -ex

# ArmoniK
kubectl create namespace $ARMONIK_NAMESPACE || true

kubectl delete secret $ARMONIK_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=redis_credentials=$ARMONIK_REDIS_CREDENTIALS_DIRECTORY/redis-credentials.json

kubectl delete secret $ARMONIK_EXTERNAL_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=redis_credentials=$ARMONIK_REDIS_CREDENTIALS_DIRECTORY/redis-credentials.json

kubectl delete secret $ARMONIK_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_ACTIVEMQ_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=amqp_credentials=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json

kubectl delete secret $ARMONIK_MONGODB_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_MONGODB_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_MONGODB_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=mongodb_credentials=$ARMONIK_MONGODB_CREDENTIALS_DIRECTORY/mongodb-credentials.json