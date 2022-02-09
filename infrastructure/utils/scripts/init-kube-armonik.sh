#!/bin/bash
set -ex

# ArmoniK
kubectl create namespace $ARMONIK_NAMESPACE || true

kubectl delete secret $ARMONIK_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/chain.p7b

kubectl delete secret $ARMONIK_EXTERNAL_REDIS_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/chain.p7b

kubectl delete secret $ARMONIK_ACTIVEMQ_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_ACTIVEMQ_CERTIFICATES_DIRECTORY/chain.p7b

kubectl delete secret $ARMONIK_MONGODB_SECRET_NAME --namespace=$ARMONIK_NAMESPACE || true
kubectl create secret generic $ARMONIK_MONGODB_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_MONGODB_CERTIFICATES_DIRECTORY/chain.p7b