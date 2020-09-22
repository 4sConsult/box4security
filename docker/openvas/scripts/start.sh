#!/bin/bash
echo "Setting Authentication"
export USERNAME=$OPENVAS_USER
export PASSWORD=$OPENVAS_PASS

# Make sure the API listens to 0.0.0.0 and is thus accessible by other containers
sed -i 's/su -c "gvmd --listen=127.0.0.1 --port=9390" gvm/su -c "gvmd --listen=0.0.0.0 --port=9390" gvm/g' /start.sh

# Insert our config insertion before the end of start script..
sed -i "\$i echo 'Inserting 4sConsult config ...'" /start.sh
sed -i "\$i chmod +x /root/insertconfig.sh" /start.sh 
sed -i "\$i /root/insertconfig.sh" /start.sh 

echo "Starting OpenVAS"
/start.sh
