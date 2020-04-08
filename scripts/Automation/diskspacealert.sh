#!/bin/bash
CURRENT=$(df /data | grep /data | awk '{ print $5}' | sed 's/%//g')
THRESHOLD=66

if [ "$CURRENT" -gt "$THRESHOLD" ] ; then
  echo -e "BOX4s Festplattenspeicher bei Kunde: $KUNDE \n/data ist mit $CURRENT% belegt."
fi
