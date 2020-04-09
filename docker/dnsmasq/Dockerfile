FROM alpine:latest

ADD dnsmasq.conf

RUN apk --no-cache add dnsmasq && \
    cp dnsmasq.conf /etc/dnsmasq.conf

EXPOSE 53/tcp 53/udp

CMD ["dnsmasq"]
