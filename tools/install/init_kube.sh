#!/bin/bash
set -ex

# Storage
source  infrastructure/utils/envvars-storage.conf
kubectl create namespace $ARMONIK_STORAGE_NAMESPACE || true

kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt \
        --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key \
        --from-file=ca_cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/ca.crt  || true

kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties || true


# ArmoniK
source infrastructure/utils/envvars.conf

kubectl create namespace $ARMONIK_NAMESPACE || true

kubectl create namespace $ARMONIK_MONITORING_NAMESPACE || true

kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_cert_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/ca.crt \
        --from-file=certificate_pfx=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx  || true

kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_cert_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/ca.crt \
        --from-file=certificate_pfx=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx || true

kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=amqp_credentials=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json || true
