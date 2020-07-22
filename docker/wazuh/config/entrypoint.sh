#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)

# It will run every .sh script located in entrypoint-scripts folder in lexicographical order
for script in `ls /entrypoint-scripts/*.sh | sort -n`; do
  bash "$script"

done

##############################################################################
# Start Wazuh Server.
##############################################################################


#set new password
cd /var/ossec/api/configuration/auth/
node htpasswd -b -c user ${WAZUH_USER} ${WAZUH_PASS}
service wazuh-api restart

/sbin/my_init