#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Copy kibana folder over (Stored XSS and SQLi)
cp Nginx/var/www/kibana/html/bpf_filter.php /var/www/kibana/html/bpf_filter.php
cp Nginx/var/www/kibana/html/filteradministration.php /var/www/kibana/html/filteradministration.php
cp Nginx/var/www/kibana/html/kibana.php /var/www/kibana/html/kibana.php

# Copy new E-Mail data
cd /home/amadmin/box4s
sudo cp System/home/amadmin/.msmtprc /home/amadmin/.msmtprc
chown amadmin:amadmin /home/amadmin/.msmtprc
sudo cp System/etc/msmtprc /etc/msmtprc
