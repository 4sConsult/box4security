#!/bin/bash
echo "Updating OpenVAS Feed ..."
openvas-stop

greenbone-scapdata-sync --verbose
greenbone-certdata-sync --verbose
greenbone-nvt-sync --verbose
openvas-feed-update --verbose

openvas-start
openvasmd --update --verbose
openvasmd --rebuild
