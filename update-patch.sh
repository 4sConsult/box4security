<<<<<<< HEAD

##
#TAG BLANK
##
=======
#!/bin/bash
#
# Zeile für TAG
#

>>>>>>> 9a5470d6c3ae0485a1bdbfead745f59089f58515

echo "Dieses Update installiert die logstash Alarmfilterfunktion"

echo "
  DROP TABLE blocks_by_logstashfilter;
 CREATE TABLE blocks_by_logstashfilter
  (
      src_ip inet,
      src_port integer,
      dst_ip inet,
      dst_port integer,
      proto  varchar(4),
      signature_id varchar(10),
      signature varchar(256)
  )
  WITH (
      OIDS = FALSE
  )
  TABLESPACE pg_default;
  ALTER TABLE blocks_by_logstashfilter
      OWNER to postgres;" | sudo -u postgres psql box4S_db

<<<<<<< HEAD

sudo touch /var/www/kibana/ebpf/15_kibana_filter.conf
sudo ln /var/www/kibana/ebpf/15_kibana_filter.conf /etc/logstash/conf.d/suricata/15_kibana_filter.conf 
sudo chown logstash:www-data 1/var/www/kibana/ebpf/5_kibana_filter.conf 
sudo chmod 0664 1/var/www/kibana/ebpf/5_kibana_filter.conf 

=======
sudo mkdir /var/www/kibana/html/update/
sudo chown www-data:www-data /var/www/kibana/html/update/ -R
sudo cp -r /home/amadmin/box4s/Nginx/var/www/kibana/html/* /var/www/kibana/html/
sudo mkdir /var/www/kibana/ebpf
touch /var/www/kibana/ebpf/bypass_filter.bpf
sudo chown suri:www-data /var/www/kibana/ebpf/bypass_filter.bpf -R
sudo chmod 664 /var/www/kibana/ebpf/bypass_filter.bpf
echo "not (src host $INT_IP)" | sudo tee -a /var/www/kibana/ebpf/bypass_filter.bpf
echo "not (dst host $INT_IP)"  | sudo tee -a  /var/www/kibana/ebpf/bypass_filter.bpf
echo "ACHTUNG"
echo " ist das die interne IP des Systems? Wenn nicht /etc/environment INT_IP korrekt setzen"
echo "----"
echo "----"
sleep 15
echo "not (src host 127.0.0.1)"  | sudo tee -a  /var/www/kibana/ebpf/bypass_filter.bpf
echo "not (dst host 127.0.0.1)"  | sudo tee -a  /var/www/kibana/ebpf/bypass_filter.bpf
echo "INSERT INTO blocks_by_bpffilter VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES ('127.0.0.1',0,'0.0.0.0',0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES ('0.0.0.0',0,'127.0.0.1',0,'');" | sudo -u postgres psql box4S_db
echo " Install Dashboards"
sudo /home/amadmin/box4s/Scripts/Elastic_Scripts/import_saved_objects.sh /home/amadmin/box4s/Kibana/Dashboard_filterUpdate090120.ndjson
>>>>>>> 9a5470d6c3ae0485a1bdbfead745f59089f58515
