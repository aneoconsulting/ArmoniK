# Certificates

## CA
ca.crt = certificate used as authority (public key)

## Self-signed certificates
cert.crt = public key signed with CA

cert.key = private key associated to cert.crt

cert.pem, certificate.pfx = cert.crt + cert.key
```bash
cat cert.crt cert.key > cert.pem
openssl pkcs12 -export -out certificate.pfx -inkey cert.key -in cert.crt -certfile ca.crt
openssl pkcs12 -in certificate.pfx -nodes
```

## Chain
chain.pem, chain.p7b = chain of certicate public from CA to certificate used (ca.crt + cert.crt in this case)

```bash
openssl crl2pkcs7 -nocrl -certfile cert.crt -out chain.p7b -certfile ca.crt
openssl pkcs7 -print_certs -in chain.p7b
openssl pkcs7 -print_certs -in chain.p7b -out chain.pem
cat cert.crt ca.crt > chain.pem # also works
```


# Conversions
## To PEM
```bash
openssl x509 -in cert.crt -out cert.pem
openssl x509 -in cert.cer -out cert.pem
openssl x509 -in cert.der -out cert.pem
```