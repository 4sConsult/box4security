#!/bin/bash
suricata-update update-sources
suricata-update
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source ptresearch/attackdetection
suricata-update enable-source sslbl/ssl-fp-blacklist
suricata-update enable-source etnetera/aggressive
suricata-update enable-source tgreen/hunting
suricata-update
oinkmaster -C /etc/suricata/oinkmaster.conf -o /var/lib/suricata/rules

suricatasc -c ruleset-reload-nonblocking
