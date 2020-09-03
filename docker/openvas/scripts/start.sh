#!/bin/bash
echo "Setting VulnWhisperer Authentication"
# Add OpenVAS Authentication to vulnwhisperer
sed -i "s/username=.*/username=$OPENVAS_USER/g" /etc/vulnwhisperer/vulnwhisperer.ini
sed -i "s/password=.*/password=$OPENVAS_PASS/g" /etc/vulnwhisperer/vulnwhisperer.ini

export USERNAME=$OPENVAS_USER
export PASSWORD=$OPENVAS_PASS

echo "Inserting 4sConsult config ..."
chmod +x /root/insertconfig.sh
/root/insertconfig.sh

/start.sh