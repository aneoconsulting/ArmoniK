#!/bin/bash
set -ex

cd infrastructure/localhost
cp utils/envvars.conf ./envvars.conf
source ./envvars.conf

kubectl create namespace $ARMONIK_NAMESPACE
kubectl create secret generic $ARMONIK_OBJECT_STORAGE_SECRET_NAME \
    --namespace=$ARMONIK_NAMESPACE \
    --from-file=cert_file=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/cert.crt \
    --from-file=key_file=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/cert.key \
    --from-file=ca_cert_file=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/ca.crt \
    --from-file=certificate_pfx=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/certificate.pfx
kubectl create secret generic $ARMONIK_QUEUE_STORAGE_SECRET_NAME \
    --namespace=$ARMONIK_NAMESPACE \
    --from-file=$ARMONIK_QUEUE_STORAGE_CREDENTIALS_DIRECTORY/jetty-realm.properties
kubectl create secret generic $ARMONIK_QUEUE_STORAGE_SECRET_NAME_FOR_ARMONIK_COMPONENTS \
    --namespace=$ARMONIK_NAMESPACE \
    --from-file=$ARMONIK_QUEUE_STORAGE_CREDENTIALS_DIRECTORY/credentials.json