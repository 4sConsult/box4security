# vim:set ft=dockerfile:
FROM postgres:latest

RUN apt update && \
    apt install -y curl gunzip && \
    curl -O -s https://iptoasn.com/data/ip2asn-combined.tsv.gz && \
    gunzip -f ip2asn-combined.tsv.gz && \
    mv ip2asn-combined.tsv.gz /root/ip2asn-combined.tsv.gz && \
    apt remove --purge -y curl gunzip && \
    rm -rf /var/lib/apt/lists/*

# Official Postgres docker image will run .sql scripts found in this folder
COPY sql/* /docker-entrypoint-initdb.d/

# From official Postgres Image
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
