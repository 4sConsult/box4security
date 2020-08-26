FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    python3-pip\
    jq

RUN pip3 install elasticsearch-curator

ADD scripts /core4s/scripts
ADD curator /core4s/curator
ADD entry.sh /core4s/entry.sh

RUN chmod 755 /core4s/entry.sh

CMD ["sh", "-c", "tail -f /dev/null"]
