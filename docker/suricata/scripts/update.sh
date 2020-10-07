#!/bin/bash

# Move Own rules to correct folder - Only do if folder not empty
if find /root/var_lib -mindepth 1 | read; then
   mv -f /root/var_lib/* /var/lib/suricata/rules
fi

suricata-update update-sources
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source ptresearch/attackdetection
suricata-update enable-source sslbl/ssl-fp-blacklist
suricata-update enable-source etnetera/aggressive
suricata-update enable-source tgreen/hunting
suricata-update

# If this is not during install, reload the rules
if [ -z "$1" ]; then
  suricatasc -c ruleset-reload-nonblocking;
fi
