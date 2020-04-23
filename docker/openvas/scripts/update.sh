#!/bin/bash
echo "Updating OpenVAS Feed ..."
greenbone-scapdata-sync --verbose
greenbone-certdata-sync --verbose
greenbone-nvt-sync --verbose
openvas-feed-update --verbose
openvasmd --update --verbose
openvasmd --rebuild
