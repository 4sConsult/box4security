FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

RUN apt update && \
    apt install -y software-properties-common && \
    add-apt-repository ppa:oisf/suricata-stable && \
    apt update && \
    apt install -y suricata
RUN apt install -y libbpf
RUN apt install -y libhtp2
RUN apt install -y hyperscan
RUN pip3 install suricata-update
