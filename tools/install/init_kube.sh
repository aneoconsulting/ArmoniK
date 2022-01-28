#!/bin/bash
set -ex

# Storage
#source  infrastructure/utils/envvars-storage.conf
kubectl create namespace $ARMONIK_STORAGE_NAMESPACE || true

kubectl delete secret $ARMONIK_STORAGE_REDIS_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE || true
kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt \
        --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key

kubectl delete secret $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE || true
kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=certificate.pfx=$ARMONIK_STORAGE_ACTIVEMQ_CERTIFICATES_DIRECTORY/certificate.pfx \
        --from-file=jetty-realm.properties=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties

kubectl delete secret $ARMONIK_STORAGE_MONGODB_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE || true
kubectl create secret generic $ARMONIK_STORAGE_MONGODB_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=mongodb.pem=$ARMONIK_STORAGE_MONGODB_CERTIFICATES_DIRECTORY/cert.pem

# ArmoniK
#source infrastructure/utils/envvars-armonik.conf
kubectl create namespace $ARMONIK_NAMESPACE || true
kubectl create namespace $ARMONIK_MONITORING_NAMESPACE || true

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
