for i in $(find $PWD -maxdepth 1 -type d);
do
sudo git checkout $1
sudo git push origin $1
cd ..
done

