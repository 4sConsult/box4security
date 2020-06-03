FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ADD scripts/ /root/scripts/
ADD etc/ /root/etc/
ADD var_lib/ /root/var_lib/

RUN apt update && \
    apt install -y software-properties-common python python-pip && \
    add-apt-repository ppa:oisf/suricata-stable && \
    apt update && \
    apt install -y suricata oinkmaster && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/suricata/scripts/ && \
    mkdir -p /var/lib/suricata/rules/ && \
    mkdir -p /var/log/suricata && \
    mkdir -p /var/run/suricata && \
    mkdir -p /etc/suricata/ && \
    mkdir -p /var/lib/box4s && \
    touch /var/lib/box4s/suricata_suppress.bpf && \
    mv /root/etc/* /etc/suricata/ && \
    mv /root/var_lib/* /var/lib/suricata/ && \
    chmod 777 /var/lib/suricata/rules -R && \
    chmod +x /root/scripts/update.sh

USER root
CMD /usr/bin/suricata -vvv -c /etc/suricata/suricata.yaml -F /var/lib/box4s/suricata_suppress.bpf -i $SURI_INTERFACE