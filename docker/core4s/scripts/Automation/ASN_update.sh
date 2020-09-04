source /core4s/config/secrets/db.conf
cd /tmp/
curl -O -s https://iptoasn.com/data/ip2asn-combined.tsv.gz
gunzip -f ip2asn-combined.tsv.gz
docker cp ip2asn-combined.tsv db:/tmp/ip2asn-combined.tsv
if true; then
	# assume db exists.. because we create it from docker build..
	echo "DROP table asn; CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://db/box4S_db
else
	echo "box4S_db Database does not exist, creating it!"
	echo "CREATE DATABASE \"box4S_db\" OWNER postgres;" |sudo -u postgres psql
	echo "CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://db/box4S_db
fi
echo "ASN Daten aktualisiert."
rm ip2asn-combined.tsv
docker exec db /bin/bash -c "rm /tmp/ip2asn-combined.tsv*"
