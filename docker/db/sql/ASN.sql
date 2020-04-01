CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250));
COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';
