#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Schreibzugriff in Systemkonfigurationen erfordert root-Privilegien." 1>&2
  exit 1
fi

QUICKCHECK_HOST=192.168.10.251

LANIP=`hostname -I`

# if contains spaces, more than 1 IP was found, extract from different source
if [[ $LANIP =~ ( |\') ]]
then
  # TODO extract from different source
  echo
fi

echo "IP ermittelt als: $LANIP"
read -p "Korrekt (j/n)?" -n 1 -r
echo
if [[ ! $REPLY =~ ^[YyjJ]$ ]]
then
  echo "IP nicht korrekt ermittelt. Manuelle Eingabe jetzt möglich:"
  read LANIP
  echo
fi
echo "========================================="
echo "Schreibe $LANIP in Konfigurationsdateien."
#  heartbeat.yml: Monitoring Kibana Interface, Evebox Interface
#  kibana.yml: Listening-Address
