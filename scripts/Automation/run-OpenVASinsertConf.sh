#!/bin/bash
python3 -m venv .venv-openvas
source .venv-openvas/bin/activate
pip install python-gvm
python $BASEDIR$GITDIR/scripts/Automation/OpenVASinsertConf.py
deactivate
echo "OpenVAS Config Full and Fast without Default Account Check and Bruteforce imported."
rm -r .venv-openvas
