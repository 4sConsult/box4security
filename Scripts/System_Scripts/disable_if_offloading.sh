#!/bin/bash

# Copyright(C) 2017, Stamus Networks
# All rights reserved
# Part of Debian SELKS scripts
# Written by Peter Manev <pmanev@stamus-networks.com>
#
# Please run on Debian
#
# This script comes with ABSOLUTELY NO WARRANTY!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.



interface=$1
ARGS=1         # The script requires 1 argument.


echo -e "\n The supplied network interface is :  ${interface} \n";

  if [ $# -ne "$ARGS" ];
    then
      echo -e "\n USAGE: `basename $0` -> the script requires 1 argument - a network interface!"
      echo -e "\n Please supply a network interface. Ex - ./disable-if-offloading.sh eth0 \n"
      exit 1;
  fi

/sbin/ethtool -G ${interface} rx 4096 >/dev/null 2>&1 ;
for i in rx tx sg tso ufo gso gro lro rxvlan txvlan ntuple rxhash; do /sbin/ethtool -K ${interface} $i off >/dev/null 2>&1; done;

/sbin/ethtool -A ${interface} rx off tx off >/dev/null 2>&1;
#/sbin/ip link set ${interface} promisc on up >/dev/null 2>&1;
/sbin/ethtool -C ${interface} rx-usecs 1 rx-frames 0 >/dev/null 2>&1;
/sbin/ethtool -L ${interface} combined 1 >/dev/null 2>&1;
/sbin/ethtool -C ${interface} adaptive-rx off >/dev/null 2>&1;

echo -e "###################################"
echo -e "# CURRENT STATUS - NIC OFFLOADING #"
echo -e "###################################"
/sbin/ethtool -k ${interface}
echo -e "######################################"
echo -e "# CURRENT STATUS - NIC RINGS BUFFERS #"
echo -e "######################################"
/sbin/ethtool -g ${interface}
