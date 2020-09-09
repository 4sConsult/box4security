#!/bin/sh
if [ $# -eq 0 ]
  then
    WAZUH_VERSION=3.12.1
  else
    WAZUH_VERSION=$1
fi
echo "Downloadindg Wazuh Client Files of Version" $WAZUH_VERSION
workdir=/core4s/workfolder/wazuh_files
if [ ! -d "$workdir" ];then
        mkdir $workdir
fi
cd $workdir
#download redhat/centos
redhat_download=https://packages.wazuh.com/3.x/yum/wazuh-agent-$WAZUH_VERSION-1.x86_64.rpm
wget $redhat_download -q -O redhat_centos-wazuh-agent.rpm
#download debian/ubuntu
debian_download=https://packages.wazuh.com/3.x/apt/pool/main/w/wazuh-agent/wazuh-agent_$WAZUH_VERSION-1_amd64.deb
wget $debian_download -q -O debian_ubuntu-wazuh-agent.deb
#download windows
windows_doanload=https://packages.wazuh.com/3.x/windows/wazuh-agent-$WAZUH_VERSION-1.msi
wget $windows_doanload -q -O windows-wazuh-agent.msi
#download macos
macos_download=https://packages.wazuh.com/3.x/osx/wazuh-agent-$WAZUH_VERSION-1.pkg
wget $macos_download -q -O macos-wazuh-agent.pkg

echo "Done"
