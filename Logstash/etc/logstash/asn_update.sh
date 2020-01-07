cd /tmp/
curl -O -s https://iptoasn.com/data/ip2asn-combined.tsv.gz 
gunzip -f ip2asn-combined.tsv.gz

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw box4s_db;then
	echo "box4s_db Database already exists, only updating ASN Data!"
	echo "DROP table asn; CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" |sudo -u postgres psql box4s_db
	echo "Done with ASN table!"
else
	echo "box4s_db Database does not exist, creating it!"
	echo "CREATE DATABASE box4s_db OWNER postgres;" |sudo -u postgres psql
	echo "CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" |sudo -u postgres psql box4s_db
	echo "Done with box4s_db Database and ASN table!"
fi
rm ip2asn-combined.tsv