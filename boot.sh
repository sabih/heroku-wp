#!/bin/bash

# Write certs in env to files and replace with path
if [ -n "$CLEARDB_SSL_KEY" -a -n "$CLEARDB_SSL_CERT" -a -n "$CLEARDB_SSL_CA" ]
then
  mkdir "/app/certs"
  echo "$CLEARDB_SSL_KEY" > /app/certs/key.pem
  echo "$CLEARDB_SSL_CERT" > /app/certs/cert.pem
  echo "$CLEARDB_SSL_CA" > /app/certs/ca.pem
  export CLEARDB_SSL_KEY="/app/certs/key.pem"
  export CLEARDB_SSL_CERT="/app/certs/cert.pem"
  export CLEARDB_SSL_CA="/app/certs/ca.pem"
  export CLEARDB_SSL="ON"
else
  unset CLEARDB_SSL_KEY
  unset CLEARDB_SSL_CERT
  unset CLEARDB_SSL_CA
fi
