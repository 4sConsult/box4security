
sudo service logstash stop
sudo rm /var/lib/logstash/openvas_sincedb
sudo rm /var/lib/logstash/openvas/* -r
sudo $BASEDIR$GITDIR/Scripts/Elastic_Scripts/delete_index.sh logstash-vulnwhisprer-*
sudo rm /var/lib/logstash/openvas/database/*
sudo /usr/local/bin/vuln_whisperer -c /usr/local/etc/vuln_openvas.ini -s openvas
