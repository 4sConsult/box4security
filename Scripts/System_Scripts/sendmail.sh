#!/bin/bash
# $1 = Receipient
# $2 = Subject
# Body from stdin
BODY=""
while read LINE; do
  if [[ ! -z $LINE ]]; then
    BODY="$BODY\n$LINE"
  fi
done < /dev/stdin
if [[ -z $BODY ]]; then
  exit
fi
ctr=0
while [ $ctr -lt 6 ]; do
        echo -e $BODY | sed "1 i\To:BOX4s <box@4sconsult.de>\nSubject: [Kunde: $KUNDE] BOX4s $2\n\n" | msmtp $1
        retVal=$?
        if [ $retVal -eq 0 ]; then
         break
        fi
  ctr=$[$ctr+1]
  # sleep a bit
  sleep ${ctr}m
done
