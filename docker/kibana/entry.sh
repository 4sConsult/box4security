#!/bin/sh

#insert wazuh startup
echo "hosts:\n  - default:\n     url: https://${INT_IP}\n     port: 55000\n     user: box4s\n     password: wa3hz0hPW\n" > /usr/share/kibana/optimize/wazuh/config/wazuh.yml
#make sure container does not restart
exec "$@"
