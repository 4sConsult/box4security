cd /tmp/
curl -O -s https://iptoasn.com/data/ip2asn-combined.tsv.gz
gunzip -f ip2asn-combined.tsv.gz

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw ASN_lookup_test;then
	echo "DROP table asn; CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" |sudo -u postgres psql ASN_lookup_test
else
	echo "ASN_lookup_test Database does not exist, creating it!"
	echo "CREATE DATABASE \"ASN_lookup_test\" OWNER postgres;" |sudo -u postgres psql
	echo "CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" |sudo -u postgres psql ASN_lookup_test
fi
echo "ASN Daten aktualisiert."
rm ip2asn-combined.tsv
