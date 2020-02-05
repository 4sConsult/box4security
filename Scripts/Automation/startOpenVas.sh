#!/bin/bash
openvas_status=$(/usr/sbin/service openvas-manager status | grep Active 2>&1)
if [[ $openvas_status =~ failed|inactive ]]
then
	# Delete the lock if older than 360 minutes - will produce output again!
	find /var/run/ -name startopenvas.sh.lock -type f -mmin +360 -delete
	if [[ ! -e /var/run/startopenvas.sh.lock ]]
	then
		# Create file lock - no output if exists!
		echo "Openvas not running properly. Will try to restart."
		touch /var/run/startopenvas.sh.lock
	fi
	/usr/sbin/service openvas-manager start
elif [[ $openvas_status =~ activating|running && -e /var/run/startopenvas.sh.lock ]] ; then
	rm /var/run/startopenvas.sh.lock
	echo -e "OpenVAS restarted. New status: \n $openvas_status"
fi

gsa_status=$(/usr/sbin/service greenbone-security-assistant status | grep Active 2>&1)
if [[ $gsa_status =~ failed|inactive ]]
then
	# Delete the lock if older than 360 minutes - will produce output again!
	find /var/run/ -name startopenvas-GSA.sh.lock -type f -mmin +360 -delete
	if [[ ! -e /var/run/startopenvas-GSA.sh.lock ]]
	then
		# Create file lock - no output if exists!
		echo "GSA not running properly. Will try to restart."
		touch /var/run/startopenvas-GSA.sh.lock
	fi
	systemctl start greenbone-security-assistant
elif [[ $gsa_status =~ activating|running && -e /var/run/startopenvas-GSA.sh.lock ]] ; then
	rm /var/run/startopenvas-GSA.sh.lock
	echo -e "Greenbone Security Assistant restarted. New status: \n $gsa_status"
fi