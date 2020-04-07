#!/bin/bash

IFACE=$(cat /etc/box4s/suricata/INTERFACE)
echo $IFACE

/usr/bin/suricata -vvv -c /etc/suricata/suricata.yaml -F /var/lib/box4s/suricata_suppress.bpf -i $IFACE
