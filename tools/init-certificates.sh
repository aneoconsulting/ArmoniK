#! /bin/sh

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
