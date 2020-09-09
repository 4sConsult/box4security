FROM ubuntu:latest

# Install all programs
RUN apt-get update && apt-get install -y \
    bc\
    python3\
    python3-venv\
    python3-pip\
    curl\
    jq\
    msmtp\
    cron\
    postgresql-client\
    unzip\
    wget

# Install docker
RUN curl -sSL https://get.docker.com/ | sh

# Install Elastic curator and Flask
RUN pip3 install elasticsearch-curator Flask

# Add files from git
ADD scripts /core4s/scripts
ADD curator /core4s/curator
ADD core4s.crontab /core4s/core4s.crontab
ADD healthcheck.py /healthcheck.py

# Add Crontab
RUN crontab /core4s/core4s.crontab

# Create cronchecker directory
RUN mkdir -p /var/log/cronchecker/

#Check health
HEALTHCHECK CMD curl --fail http://localhost:2981/ || exit 1

# Run the command on container startup
CMD cron &&\
python3 healthcheck.py
