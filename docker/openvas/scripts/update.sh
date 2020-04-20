#!/bin/bash
systemctl restart openvas-scanner
systemctl restart openvas-manager
systemctl restart greenbone-security-assistant

greenbone-scapdata-sync --verbose
greenbone-certdata-sync --verbose
openvas-feed-update --verbose
greenbone-nvt-sync --verbose
openvasmd --update --verbose
openvasmd --rebuild
