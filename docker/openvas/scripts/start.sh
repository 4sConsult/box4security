#!/bin/bash
echo "Setting Authentication"
export USERNAME=$OPENVAS_USER
export PASSWORD=$OPENVAS_PASS

/start.sh

echo "Inserting 4sConsult config ..."
chmod +x /root/insertconfig.sh
/root/insertconfig.sh