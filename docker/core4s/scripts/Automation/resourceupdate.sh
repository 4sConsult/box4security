#!/bin/bash
# Updating ASN
/bin/bash /core4s/scripts/Automation/ASN_update.sh

# Updating Geo-IP
source /core4s/config/secrets/secrets.conf
cd /tmp/
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN.zip
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
unzip -o IP2LOCATION-LITE-DB5.BIN.zip
mv -f IP2LOCATION-LITE-DB5.BIN /core4s/workfolder/var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
unzip -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
mv -f IP2LOCATION-LITE-DB5.IPV6.BIN /core4s/workfolder/var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN
