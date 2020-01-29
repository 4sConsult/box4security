cd /var/lib/logstash/openvas/
mkdir backup_reports/
cp * backup_reports/ -r

for sf in $(find $PWD -maxdepth 1 -type f);
do
        REPORT_ID=$(echo $sf | awk  '{print substr($sf,40, 32)}')
        DATE=$(echo $sf | awk  '{print substr($sf, 73, 10)}')
echo "Renaming file:"
echo "Folder: $sf"
echo "Reprot ID: $REPORT_ID"
echo "Date: $DATE"
mv openvas_scan_${REPORT_ID}_${DATE}.json openvas_scan_${DATE}_${REPORT_ID}.json
done
