#!/bin/bash
set -ex

rm -rf $ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY
mkdir -p $ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY
bash infrastructure/utils/scripts/init-certificates.sh $ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY redis

rm -rf $ARMONIK_STORAGE_ACTIVEMQ_CERTIFICATES_DIRECTORY
mkdir -p $ARMONIK_STORAGE_ACTIVEMQ_CERTIFICATES_DIRECTORY
bash infrastructure/utils/scripts/init-certificates.sh $ARMONIK_STORAGE_ACTIVEMQ_CERTIFICATES_DIRECTORY activemq

rm -rf $ARMONIK_STORAGE_MONGODB_CERTIFICATES_DIRECTORY
mkdir -p $ARMONIK_STORAGE_MONGODB_CERTIFICATES_DIRECTORY
bash infrastructure/utils/scripts/init-certificates.sh $ARMONIK_STORAGE_MONGODB_CERTIFICATES_DIRECTORY mongodb


# Storage
kubectl create namespace $ARMONIK_STORAGE_NAMESPACE || true

kubectl delete secret $ARMONIK_STORAGE_REDIS_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE || true
kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt \
        --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key

kubectl delete secret $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE || true
kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=certificate.pfx=$ARMONIK_STORAGE_ACTIVEMQ_CERTIFICATES_DIRECTORY/certificate.pfx

kubectl delete secret $ARMONIK_STORAGE_MONGODB_SECRET_NAME --namespace=$ARMONIK_STORAGE_NAMESPACE || true
kubectl create secret generic $ARMONIK_STORAGE_MONGODB_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=mongodb.pem=$ARMONIK_STORAGE_MONGODB_CERTIFICATES_DIRECTORY/cert.pem