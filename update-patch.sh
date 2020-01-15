#!/bin/bash
##
#TAG BLANK
##

echo "Update System auf v1.5.8"
sudo mkdir /var/www/kibana/html/update/
chown www-data:www-data  /var/www/kibana/html/update/
cp /home/amadmin/box4s/Nginx/var/www/kibana/html/* /var/www/kibana/html/ -r
cp /home/amadmin/box4s/Nginx/etc/nginx/nginx.conf /etc/nginx
cp /home/amadmin/box4s/Nginx/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/
sudo systemctl restart nginx


echo "Dieses Update installiert php-psql, openvm-tools und die Alarmfilterfunktion"
sudo apt install -y php-pgsql open-vm-tools

echo "
  -- DROP TABLE blocks_by_bpffilter;
 CREATE TABLE blocks_by_bpffilter
  (
      src_ip inet,
      src_port integer,
      dst_ip inet,
      dst_port integer,
      proto  varchar(4)
  )
  WITH (
      OIDS = FALSE
  )
  TABLESPACE pg_default;
  ALTER TABLE blocks_by_bpffilter
      OWNER to postgres;" | sudo -u postgres psql box4S_db

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
#Funktioniert nur bei frischen Installationen
#sudo /home/amadmin/box4s/Scripts/Elastic_Scripts/import_saved_objects.sh /home/amadmin/box4s/Kibana/Dashboard_filterUpdate090120.ndjson
echo "Install  new Suricata Index"
curl -X POST "localhost:5601/api/saved_objects/_resolve_import_errors" -H "kbn-xsrf: true" --
form file=@box4s/Kibana/Dashboard_filterUpdate090120.ndjson --form retries='[{"type":"index-pattern","id":"95298780-ce16-11e9-943f-fdbfa2556276","overwrite":true}]'
echo "Install new Visualisations"
curl -X POST "localhost:5601/api/saved_objects/_resolve_import_errors" -H "kbn-xsrf: true" --form file=@box4s/Kibana/Dashboard_filterUpdate090120.ndjson --form retries='[{"type":"visualisation","id":"f73f0e40-e37e-11e9-a3a2-adf9cc70853f","overwrite":true}]'
curl -X POST "localhost:5601/api/saved_objects/_resolve_import_errors" -H "kbn-xsrf: true" --form file=@box4s/Kibana/Dashboard_filterUpdate090120.ndjson --form retries='[{"type":"search","id":"5dccc860-cef2-11e9-943f-fdbfa2556276","overwrite":true}]'


echo "Install new Dashboard"
echo "Achtung: Filtereinstellungen werden gelöscht."
curl -X POST "localhost:5601/api/saved_objects/_resolve_import_errors" -H "kbn-xsrf: true" --form file=@box4s/Kibana/Dashboard_filterUpdate090120.ndjson --form retries='[{"type":"dashboard","id":"a7bfd050-ce1d-11e9-943f-fdbfa2556276","overwrite":true}]'




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

sudo touch /var/www/kibana/ebpf/15_kibana_filter.conf
sudo chown logstash:www-data /var/www/kibana/ebpf/15_kibana_filter.conf 
sudo chmod 0664 /var/www/kibana/ebpf/15_kibana_filter.conf
sudo ln -s /var/www/kibana/ebpf/15_kibana_filter.conf /etc/logstash/conf.d/suricata/15_kibana_filter.conf 
 
