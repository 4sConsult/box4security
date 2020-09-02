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
    nodejs\
    wget

# Install docker
RUN curl -sSL https://get.docker.com/ | sh

# Install Elastic curator
RUN pip3 install elasticsearch-curator

# Add files from git
ADD scripts /core4s/scripts
ADD curator /core4s/curator
ADD core4s.crontab /core4s/core4s.crontab
ADD healthcheck.js /healthcheck.js

# Add Crontab
RUN crontab /core4s/core4s.crontab

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

#Check health
HEALTHCHECK --interval=12s --timeout=12s --start-period=30s \
 CMD node /healthcheck.js

# Run the command on container startup
CMD cron &&\
bash /core4s/scripts/Automation/croncheck.sh init_cronchecker SUCCESS &&\
tail -f /var/log/cron.log
