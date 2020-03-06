#!/bin/bash
#exec 1 > /var/www/kibana/html/update/suricatarestart.log && exec 2 > /var/www/kibana/html/update/suricatarestart.log
echo "Restart suricata"
/usr/bin/systemctl restart suricata.service

