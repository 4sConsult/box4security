#!/bin/bash
python3 -m venv .venv-openvas
source .venv-openvas/bin/activate
python /root/OpenVASinsertConf.py
deactivate
echo "OpenVAS Config Full and Fast without Default Account Check and Bruteforce imported."
rm -r .venv-openvas
