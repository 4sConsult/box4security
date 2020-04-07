#!/bin/bash
IFACE=$(sudo ip addr | cut -d ' ' -f2| tr ':' '\n' | awk NF | grep -v lo | sed -n 2p | sudo tee -a /tmp/INTERFACE)

sudo /usr/bin/suricata -vvv -c /etc/suricata/suricata.yaml -F /var/lib/box4s/suricata_suppress.bpf -i $IFACE
