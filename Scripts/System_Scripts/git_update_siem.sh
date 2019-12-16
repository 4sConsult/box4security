BRANCH="v1.1-dev"
cd $BASEDIR/$GITDIR
if [ -z "$1" ]
then
	echo "Keine Branch angegeben:  $0 [BRANCH]"
else
	BRANCH=$1
fi
echo "Verwende Branch $BRANCH"
git fetch
git pull https://deployment:X7nrVy2JcosG96vGp9Xc@lockedbox-bugtracker.am-gmbh.de/AM-GmbH/siem.git $1

echo "#######"
echo "Done. Nun können die Configs übertragen werden"


