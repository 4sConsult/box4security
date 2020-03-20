#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Add primary keys to rule tables
echo "ALTER TABLE blocks_by_bpffilter ADD COLUMN id SERIAL PRIMARY KEY;" | sudo -u postgres psql box4S_db
echo "ALTER TABLE blocks_by_logstashfilter ADD COLUMN id SERIAL PRIMARY KEY;" | sudo -u postgres psql box4S_db
