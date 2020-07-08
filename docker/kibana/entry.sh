#!/bin/sh

#insert wazuh startup
echo -e "hosts:\n  - default:\n     url: https://${INT_IP}\n     port: 55000\n     user: ${WAZUH_USER}\n     password: ${WAZUH_PASS}\n" > /usr/share/kibana/optimize/wazuh/config/wazuh.yml
#make sure container does not restart
exec "$@"
