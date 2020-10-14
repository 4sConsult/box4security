#!/bin/bash
REPOS=(
    ssh://git@gitlab.com/4sconsult/box4s-license-server.git 
    ssh://git@gitlab.com/4sconsult/elastic-standard.git 
    ssh://git@gitlab.com/4sconsult/azure.git 
    ssh://git@gitlab.com/4sconsult/encryptpitsa.git
    ssh://git@gitlab.com/4sconsult/docs.git
    ssh://git@gitlab.com/4sconsult/scrum-guide.git
    ssh://git@gitlab.com/4sconsult/box4s.git
)
DATE=$(date +%d.%m.%Y)
echo "Creating encrypted 4sConsult repo backups for $DATE."
echo -n "Recreating working folders.. "
rm -rf /tmp/backup4srepos
mkdir -p /tmp/backup4srepos
echo -n "[ /tmp/backup4srepos "
rm -rf /tmp/backup4sbundles
mkdir -p /tmp/backup4sbundles
echo " /tmp/backup4sbundles ]"
cd /tmp/backup4srepos
echo -n "Mirroring repos.. [ "
for r in "${REPOS[@]}"; do 
    echo -n "${r##*/} "
    git clone --mirror $r >/dev/null 2>&1
done
echo " ]"
echo "Bundling repos.."
for D in `find /tmp/backup4srepos -mindepth 1 -maxdepth 1 -type d`
do
    cd $D
    repo=${PWD##*/}
    echo -n "- $repo "
    git bundle create $repo.bundle --all >/dev/null 2>&1
    echo "[OK]"
    # No such file may occur here if the repository is empty.
    # No bundles are created for emtpy repositories.
    cp $repo.bundle /tmp/backup4sbundles
done

echo -n "Archiving the bundles.. "
cd /tmp/backup4sbundles
tar cfz 4srepos-$DATE.tar.gz *
echo "[OK]"
echo "Archive contents: "
tar -ztvf 4srepos-$DATE.tar.gz

echo -n "Encrypting archive for developers' keys.. "
gpg --encrypt \
    --recipient christoph.meyer@4sconsult.de \
    --recipient constantin.tillmann@4sconsult.de \
    --recipient jan.guenther@4sconsult.de \
    4srepos-$DATE.tar.gz
echo "[OK]"
cp 4srepos-$DATE.tar.gz.gpg /tmp/4srepos-$DATE.tar.gz.gpg
rm -rf /tmp/backup4srepos
rm -rf /tmp/backup4sbundles
echo "Success! Find your encrypted archive file at /tmp/4srepos-$DATE.tar.gz.gpg"
