#!/bin/bash
# Updating ASN
/bin/bash $BASEDIR$GITDIR/scripts/Automation/ASN_update.sh

# Updating Geo-IP
# IP2LOCATION Token
IP2TOKEN="MyrzO6sxNLvoSEaGtpXoreC1x50bRGmDfNd3UFBIr66jKhZeGXD7cg9Jl9VdQhQ5"
cd /tmp/
curl "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN
curl "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB9LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN
