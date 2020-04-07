FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ADD scripts/ /root/scripts/
ADD etc/ /root/etc/
ADD var_lib/ /root/var_lib/

RUN apt update && \
    apt install -y software-properties-common python python-pip && \
    add-apt-repository ppa:oisf/suricata-stable && \
    apt update && \
    apt install -y suricata oinkmaster && \
    rm -rf /var/lib/apt/lists/* &&
    mkdir -p /var/lib/suricata/scripts/ && \
    mkdir -p /var/log/suricata && \
    mkdir -p /var/run/suricata && \
    mv /root/etc/* /etc/suricata/ && \
    mv /root/scripts/* /var/lib/suricata/scripts/ && \
    mv /root/var_lib/* /var/lib/suricata/ && \
    groupadd suri && \
    useradd suri -g suri && \
    chown suri:suri /etc/suricata -R && \
    chown suri:suri /var/lib/suricata -R && \
    chown suri:suri /var/log/suricata -R && \
    chown suri:suri /var/run/suricata -R && \
    chmod +x /var/lib/suricata/scripts/update.sh
    /var/lib/suricata/scripts/update.sh && \
    oinkmaster -C /etc/suricata/oinkmaster.conf -o /var/lib/suricata/rules && \

CMD ["/usr/bin/suricata" "-c" "/etc/suricata/suricata.yaml", "-F" "/var/lib/box4s/suricata_suppress.bpf"]
