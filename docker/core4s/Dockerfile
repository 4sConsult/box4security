FROM ubuntu:latest

# Install all programs
RUN apt-get update && apt-get install -y \
    python3-pip\
    curl\
    jq\
    msmtp\
    cron

# Install docker
RUN curl -sSL https://get.docker.com/ | sh

# Install Elastic curator
RUN pip3 install elasticsearch-curator

# Add files from git
ADD scripts /core4s/scripts
ADD curator /core4s/curator
ADD core4s.crontab /core4s/core4s.crontab

# Add Crontab
RUN crontab /core4s/core4s.crontab

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD cron &&\
bash /core4s/scripts/croncheck.sh init_cronchecker SUCCESS &&\
tail -f /var/log/cron.log
