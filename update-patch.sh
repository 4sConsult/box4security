#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Copy kibana folder over (Stored XSS and SQLi)
cp Nginx/var/www/kibana/html/bpf_filter.php /var/www/kibana/html/bpf_filter.php
cp Nginx/var/www/kibana/html/filteradministration.php /var/www/kibana/html/filteradministration.php
cp Nginx/var/www/kibana/html/kibana.php /var/www/kibana/html/kibana.php

# Openconnect nachträglichen installieren
sudo apt install -y openconnect

# Hosts Datei aktualisieren
sudo cp System/etc/hosts /etc/hosts
