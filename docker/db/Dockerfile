# vim:set ft=dockerfile:
FROM postgres:latest

# Official Postgres docker image will run .sql scripts found in this folder
COPY sql/* /docker-entrypoint-initdb.d/


# From official Postgres Image
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
