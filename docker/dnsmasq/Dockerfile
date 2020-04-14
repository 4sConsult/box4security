FROM alpine:latest

ADD dnsmasq.conf /tmp/dnsmasq.conf

RUN apk --no-cache add dnsmasq && \
    cp /tmp/dnsmasq.conf /etc/dnsmasq.conf

EXPOSE 53/tcp 53/udp

RUN dnsmasq --test
USER dnsmasq
CMD ["dnsmasq", "-k"]
