openssl pkcs12 -export -in tls/redis.crt -inkey tls/redis.key -certfile tls/ca.crt -out tls/certificate.pfx -passout pass:

