#!/bin/bash

greenbone-scapdata-sync --verbose
greenbone-certdata-sync --verbose
openvas-feed-update --verbose
greenbone-nvt-sync --verbose
openvasmd --update --verbose
openvasmd --rebuild
