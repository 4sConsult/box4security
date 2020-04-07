FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

RUN add-apt-repository ppa:oisf/suricata-stable && \
    apt update && \
    apt install -y suricata
RUN apt install -y libbpf
RUN apt install -y libhtp2
RUN apt install -y hyperscan
RUN pip3 install suricata-update
