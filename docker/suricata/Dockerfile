FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ADD scripts/ /root/scripts/
ADD etc/ /root/etc/
ADD var_lib/ /root/var_lib/

RUN apt update && \
    apt install -y software-properties-common python python-pip && \
    add-apt-repository ppa:oisf/suricata-stable && \
    apt update && \
    apt install -y suricata && \
    rm -rf /var/lib/apt/lists/* &&
    mkdir -p /var/lib/suricata/scripts/ && \
    mv /root/etc/* /etc/suricata/ && \
    mv /root/scripts/* /var/lib/suricata/scripts/

RUN groupadd suri && \
    useradd suri -g suri && \
    mkdir -p /var/log/suricata && \
    mkdir -p /var/run/suricata && \
    chown suri:suri /etc/suricata -R && \
    chown suri:suri /var/lib/suricata -R && \
    chown suri:suri /var/log/suricata -R && \
    chown suri:suri /var/run/suricata - R && \

CMD ["/usr/bin/suricata" "-c" "/etc/suricata/suricata.yaml"]
