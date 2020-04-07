FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

RUN apt update && \
    apt install -y software-properties-common python python-pip && \
    add-apt-repository ppa:oisf/suricata-stable && \
    apt update && \
    apt install -y suricata && \
    pip install suricata-update && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/*
