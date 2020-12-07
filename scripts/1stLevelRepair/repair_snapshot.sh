#$1 contains name of the snapshot to restore
Snaplocation="/var/lib/box4s/snapshots"
#check if snap has .zip ending or not
Snap="$Snaplocation/$1"
#Unzip snapshot


echo $Snap
echo $Snap | sed 's,^[^/]*/*/,,'
function moveFiles(){
  target_folder=$1
  mv -f $Snap $target_folder
  }


folders:
/etc/box4s
/var/lib/box4s
/var/lib/postgresql
/var/lib/box4s_suricata_rules
/etc/box4s/logstash
/var/lib/logstash
/var/lib/elastalert
/var/lib/box4s_docs

#todo: permissions, unzip snapshot


#function copyFolder(){
  #Copy input folder to temporary folder
#  outFolder=$folder/$1
#  mkdir $outFolder -p
#  cp -r $1 $folder/$1
#}

#make sure that permissions are set the same as in install script
#Check if version is the same as currenct installed one
