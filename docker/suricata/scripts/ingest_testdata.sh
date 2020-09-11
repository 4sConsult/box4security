#!/bin/bash

# Location of the suricata conf
CONF_FILE=/etc/suricata/suricata.yaml

# Directory of where all the PCAP files are
# Example of files to be downloaded with the wget command
# wget -r -np -k https://archive.wrccdc.org/pcaps/2018/
mkdir -p /data/suricata/pcap/
chmod 777 -R /data/suricata/pcap/
PCAP_DIR=/data/suricata/pcap/

# Download just a few pcaps
wget -P /data/suricata/pcap/ https://archive.wrccdc.org/pcaps/2018/wrccdc.2018-03-23.010356000000000.pcap.gz
wget -P /data/suricata/pcap/ https://archive.wrccdc.org/pcaps/2018/wrccdc.2018-03-23.011834000000000.pcap.gz
wget -P /data/suricata/pcap/ https://archive.wrccdc.org/pcaps/2018/wrccdc.2018-03-23.013421000000000.pcap.gz
wget -P /data/suricata/pcap/ https://archive.wrccdc.org/pcaps/2018/wrccdc.2018-03-23.020844000000000.pcap.gz
wget -P /data/suricata/pcap/ https://archive.wrccdc.org/pcaps/2018/wrccdc.2018-03-23.021720000000000.pcap.gz

# Get all files in a list
file_list=()
while IFS= read -d $'\0' -r file ; do
  file_list=("${file_list[@]}" "$file")
done < <(find "${PCAP_DIR}" -name *.pcap.gz -print0)

# Simple for loop over all the files
for i in "${!file_list[@]}"
do
  PCAP_FILE=${file_list[$i]}
  echo "$i/${#file_list[@]} Processing file: $PCAP_FILE"
  gunzip -c "$PCAP_FILE" > /tmp/temp.pcap
  sudo suricata -v -c $CONF_FILE -r "/tmp/temp.pcap" --set unix-command.enabled=false
done

# Delete the pcaps, to save some storage
sudo rm -r /data/suricata/pcap/*
sudo rm /tmp/temp.pcap