FROM ubuntu:19.10
RUN	apt update && \
	apt install -y curl sudo wget apt-utils && \
	/bin/bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)" && \
  apt-fast update && \
	apt-fast install -y apt-transport-https openjdk-11-jre gnupg software-properties-common python python-pip && \
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
  echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
	add-apt-repository ppa:oisf/suricata-stable && \
	apt-fast autoremove -y && \
	apt-fast autoclean && \
	apt-fast clean
