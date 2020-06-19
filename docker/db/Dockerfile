# vim:set ft=dockerfile:
FROM postgres:latest

# Official Postgres docker image will run .sql scripts found in this folder
COPY sql/* /docker-entrypoint-initdb.d/

# Initial IP2ASN setup
RUN apt update && \
    apt install -y curl gzip && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://iptoasn.com/data/ip2asn-combined.tsv.gz -o /tmp/ip2asn-combined.tsv.gz && \
    gunzip -f /tmp/ip2asn-combined.tsv.gz

# From official Postgres Image
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
