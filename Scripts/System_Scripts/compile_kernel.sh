 make oldconfig
 make menuconfig
 make -j16
 make modules 
 make modules_install
 make install
 cd ~/suricata/suricata
 #make clean && make
 sudo  make install-full
