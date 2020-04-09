#!/bin/bash

sudo /usr/bin/suricata -vvv -c /etc/suricata/suricata.yaml -F /var/lib/box4s/suricata_suppress.bpf -i $SURI_INTERFACE
