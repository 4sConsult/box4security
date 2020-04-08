#!/bin/bash
# Creates self signed certificate in a interactive session using
# default values from box4security-ssl.conf
# Key is without a passphrase
openssl req -config box4security-ssl.conf -new -x509 -sha256 -newkey rsa:4096 -nodes -keyout box4security.key.pem -days 365 -out box4security.cert.pem

chmod 600 box4security.key.pem
chmod 644 box4security.cert.pem
