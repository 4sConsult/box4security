FROM ubuntu:latest

# Install all programs
RUN apt-get update && apt-get install -y \
    python3-pip\
    jq\
    msmtp\
    cron

RUN pip3 install elasticsearch-curator

# Add files from git
ADD scripts /core4s/scripts
ADD curator /core4s/curator
ADD entry.sh /core4s/entry.sh
ADD core4s.crontab /core4s/core4s.crontab

RUN chmod 755 /core4s/entry.sh

# Make Crontab executable and add it
RUN chmod 0644 /core4s/core4s.crontab
RUN crontab /core4s/core4s.crontab


# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log
