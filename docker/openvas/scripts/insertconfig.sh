#!/bin/bash
CONFIG=/etc/openvas/4s-OpenVAS.xml

if [ -f "$CONFIG" ]; then
  python3 -m venv .venv-openvas
  source .venv-openvas/bin/activate
  pip install python-gvm
  python3 /root/config.py
  deactivate
  echo "OpenVAS Config Full and Fast without Default Account Check and Bruteforce imported."
  rm -r .venv-openvas
  rm $CONFIG
else
  echo "Config has already been imported"
fi
