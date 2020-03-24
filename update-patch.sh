#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Copy kibana folder over (Stored XSS and SQLi)
cp Nginx/var/www/kibana/html/bpf_filter.php /var/www/kibana/html/bpf_filter.php
cp Nginx/var/www/kibana/html/filteradministration.php /var/www/kibana/html/filteradministration.php
cp Nginx/var/www/kibana/html/kibana.php /var/www/kibana/html/kibana.php

# Scores Index in vorheriger Version fehlerhaft gewesen
cd /home/amadmin/box4s/Scripts/Automation/score_calculation/
./install_index.sh
