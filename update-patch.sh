
##
#TAG BLANK
##

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
sudo ln /var/www/kibana/ebpf/15_kibana_filter.conf /etc/logstash/conf.d/suricata/15_kibana_filter.conf 
sudo chown logstash:www-data 1/var/www/kibana/ebpf/5_kibana_filter.conf 
sudo chmod 0664 1/var/www/kibana/ebpf/5_kibana_filter.conf 

