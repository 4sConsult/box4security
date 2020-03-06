FROM python:3.6-alpine as py-ea
ARG ELASTALERT_VERSION=v0.2.1
ENV ELASTALERT_VERSION=${ELASTALERT_VERSION}
# URL from which to download Elastalert.
ARG ELASTALERT_URL=https://github.com/Yelp/elastalert/archive/$ELASTALERT_VERSION.zip
ENV ELASTALERT_URL=${ELASTALERT_URL}
# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert

WORKDIR /opt

#RUN apk add --update --no-cache ca-certificates openssl-dev openssl python3-dev=3.6.8-r0 python3=3.6.8-r0 py-pip=9.0.1-r1 py3-yaml libffi-dev gcc musl-dev wget && \
RUN apk add --update --no-cache npm ca-certificates openssl-dev openssl python3-dev python3 py-pip py3-yaml libffi-dev gcc musl-dev wget && \
# Download and unpack Elastalert.
    wget -O elastalert.zip "${ELASTALERT_URL}" && \
    unzip elastalert.zip && \
    rm elastalert.zip && \
    mv e* "${ELASTALERT_HOME}"

WORKDIR "${ELASTALERT_HOME}"

#wget -O elastalert.zip "${ELASTALERT_URL}" && \
# Install Elastalert.
# see: https://github.com/Yelp/elastalert/issues/1654
#RUN sed -i 's/jira>=1.0.10/jira>=1.0.10,<1.0.15/g' setup.py && \
#
RUN sed -i 's/jira>=1.0.10/jira<=2.0.0/g' setup.py && \
    python3 setup.py install && \
    pip3 install -r requirements.txt
#FROM node:alpine

FROM python:3.6-alpine
LABEL maintainer="BitSensor <dev@bitsensor.io>"
# Set timezone for this container
ENV TZ Etc/UTC

RUN apk add --update --no-cache npm msmtp curl tzdata python2 python3 make libmagic
RUN ln -sf /usr/bin/msmtp /usr/sbin/sendmail
COPY --from=py-ea /usr/local/lib/python3.6/site-packages /usr/local/lib/python3.6/site-packages
#COPY --from=py-ea /usr/lib/python3.7/site-packages /usr/lib/python3.7/site-packages
COPY --from=py-ea /opt/elastalert /opt/elastalert
COPY --from=py-ea /usr/local/bin/elastalert* /usr/bin/

WORKDIR /opt/elastalert-server
COPY . /opt/elastalert-server

RUN npm install --production --quiet
COPY config/elastalert.yaml /opt/elastalert/config.yaml
COPY config/elastalert-test.yaml /opt/elastalert/config-test.yaml
COPY config/config.json config/config.json
COPY rule_templates/ /opt/elastalert/rule_templates
COPY elastalert_modules/ /opt/elastalert/elastalert_modules

# Add default rules directory
# Set permission as unpriviledged user (1000:1000), compatible with Kubernetes
RUN addgroup -S node && adduser -S node -G node
RUN mkdir -p /opt/elastalert/rules/ /opt/elastalert/server_data/tests/ \
    && chown -R node:node /opt

USER node

EXPOSE 3030
ENTRYPOINT ["npm", "start"]
