#!/bin/bash

set -e

USER_CERT_CN="armonik.local.tp.participant"
USER_CERT_FILE_NAME="custom.submitter"

# Set up directories
mkdir -p customCA/{certs,private}
chmod 700 customCA/private
touch customCA/customCAindex
echo 1000 > customCA/customCAserial

# Generate the private key for the CA
openssl genrsa -out customCA/private/ca.key 4096

# Generate a self signed root certificate that will act as CA
openssl req -x509 -new -nodes \
  -key customCA/private/ca.key \
  -sha256 \
  -days 1024 \
  -out customCA/certs/ca.crt -subj \
  "/C=FR/L=Paris/O=ANEO/CN=ANEO Formation Armonik - Private Certificate Authority"

# Generate the private key for the user certificate (4096 bits)
openssl genrsa -out customCA/private/${USER_CERT_FILE_NAME}.key 4096

# Create a certificate signing request (CSR) for the user
openssl req -new -key customCA/private/${USER_CERT_FILE_NAME}.key \
  -out customCA/${USER_CERT_FILE_NAME}.csr \
  -subj "/C=FR/L=Paris/O=ANEO/CN=${USER_CERT_CN}" \
  -config openssl.extensions.conf

# Generate the user certificate signed by the CA
openssl x509 -req -in customCA/${USER_CERT_FILE_NAME}.csr \
  -CA customCA/certs/ca.crt \
  -CAkey customCA/private/ca.key \
  -CAcreateserial \
  -out customCA/certs/${USER_CERT_FILE_NAME}.crt \
  -days 500 \
  -sha256  \
  -extfile openssl.extensions.conf \
  -extensions req_ext

# Create a PKCS#12 file containing the user certificate and private key without a password
openssl pkcs12 -export \
  -out customCA/certs/${USER_CERT_FILE_NAME}.p12 \
  -inkey customCA/private/${USER_CERT_FILE_NAME}.key \
  -in customCA/certs/${USER_CERT_FILE_NAME}.crt \
  -certfile customCA/certs/ca.crt \
  -passout pass:

# Output the results
echo "CA Certificate: customCA/certs/ca.crt"
echo "User Certificate: customCA/certs/${USER_CERT_FILE_NAME}.crt"
echo "User PKCS#12 File: customCA/certs/${USER_CERT_FILE_NAME}.p12"
echo "CA Private Key: customCA/private/ca.key"
echo "User Private Key: customCA/private/${USER_CERT_FILE_NAME}.key"

# Verify altname is set
openssl x509 -noout -ext subjectAltName -in "customCA/certs/${USER_CERT_FILE_NAME}.crt"

