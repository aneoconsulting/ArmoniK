#! /bin/sh


# Certificate Generation Script
#
# Purpose:
# This script automates the process of generating a self-signed root certificate
# and a certificate for a specified Fully Qualified Domain Name (FQDN) or IP address.
# It utilizes OpenSSL to create a root private key, self-sign a root certificate,
# generate a certificate signing request (CSR), and sign the request with the root
# certificate. The script also converts the generated certificate and private key
# into various formats for easy use.
#
# Features:
# - Generates a root private key and self-signed root certificate.
# - Creates a certificate signing request (CSR) for a specified FQDN or IP address.
# - Signs the CSR with the root certificate to produce a valid certificate.
# - Outputs the certificate and private key in PEM format.
# - Exports the certificate and private key to a PKCS#12 (.pfx) file for compatibility
#   with various applications.
# - Generates a certificate chain in both PKCS#7 and PEM formats.
#
# Usage:
# To use the script, provide the desired root common name (CN) as the second argument
# when executing the script. Ensure that the output directory (`OUTDIR`) is set correctly
# to store the generated files.
#
# Example:
# ./script.sh <other_arguments> <root_common_name>
#
# Output:
# The script will generate the following files in the specified output directory:
# - root.key: The private key for the root certificate.
# - root.crt: The self-signed root certificate.
# - cert.key: The private key for the generated certificate.
# - cert.csr: The certificate signing request.
# - cert.crt: The signed certificate.
# - cert.pem: The combined certificate and private key in PEM format.
# - certificate.pfx: The PKCS#12 file containing the certificate and private key.
# - chain.p7b: The certificate chain in PKCS#7 format.
# - chain.pem: The certificate chain in PEM format.
#
# Requirements:
# - OpenSSL must be installed on the system to run this script.

set -ex

OUTDIR="$1"
ROOTCN="$2"

FQDN=127.0.0.1

# generate root private key
openssl genrsa 4096 > "${OUTDIR}/root.key"
# self sign root certificate
openssl req \
        -new \
        -x509 \
        -nodes \
        -sha256 \
        -key "${OUTDIR}/root.key" \
        -days 3650 \
        -subj "/C=AU/CN=$ROOTCN" \
        -out "${OUTDIR}/root.crt"


# generate request
SAN="IP:$FQDN" openssl req \
        -newkey rsa:4096 \
        -nodes -sha256 \
        -keyout "${OUTDIR}/cert.key" \
        -subj "/C=AU/CN=$FQDN" \
        -out "${OUTDIR}/cert.csr"


# sign request with root ca
SAN="IP:$FQDN" openssl x509 \
        -req -sha256 \
        -days 3650 \
        -in "${OUTDIR}/cert.csr" \
        -CA "${OUTDIR}/root.crt" \
        -CAkey "${OUTDIR}/root.key" \
        -CAcreateserial \
        -out "${OUTDIR}/cert.crt"

# convert certificate and private key
cat "${OUTDIR}/cert.crt" "${OUTDIR}/cert.key" > "${OUTDIR}/cert.pem"
openssl pkcs12 -export -out "${OUTDIR}/certificate.pfx" -inkey "${OUTDIR}/cert.key" -in "${OUTDIR}/cert.crt" -certfile "${OUTDIR}/root.crt" -passout pass:

# generate chain
openssl crl2pkcs7 -nocrl -certfile "${OUTDIR}/cert.crt" -out "${OUTDIR}/chain.p7b" -certfile "${OUTDIR}/root.crt"
openssl pkcs7 -print_certs -in "${OUTDIR}/chain.p7b" -out "${OUTDIR}/chain.pem"
