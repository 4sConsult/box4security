#!/bin/bash

suricata-update update-sources
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source ptresearch/attackdetection
suricata-update enable-source sslbl/ssl-fp-blacklist
suricata-update enable-source etnetera/aggressive
suricata-update enable-source tgreen/hunting
suricata-update

# If this is not during install, reload the rules
# And also insert the self-created rules from the copied git folder
if [ -z "$1" ]; then
  suricatasc -c ruleset-reload-nonblocking;
  sudo cp -rf /root/var_lib/. /var/lib/suricata/rules
fi
