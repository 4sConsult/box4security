echo "INSERT INTO blocks_by_bpffilter VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES (0.0.0.0,0,'"$INT_IP"',0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES (127.0.0.1,0,0.0.0.0,0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES ('"$INT_IP"',0,127.0.0.1,0,'');" | sudo -u postgres psql box4S_db


