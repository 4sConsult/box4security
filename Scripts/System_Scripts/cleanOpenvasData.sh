
 sudo service logstash stop                                                            
 sudo rm /var/lib/logstash/openvas_sincedb                                             
 sudo rm /var/lib/logstash/openvas/database/report_tracker.db                          
 sudo rm /var/lib/logstash/openvas/*.json
sudo /usr/local/bin/vuln_whisperer -c /usr/local/etc/vuln_openvas.ini -s openvas 
