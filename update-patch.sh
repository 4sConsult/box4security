echo "Update System auf v1.5.7"
sudo mkdir /var/www/kibana/html/update/
chown www-data:www-data  /var/www/kibana/html/update/
cp /home/amadmin/box4s/Nginx/var/www/kibana/html/* /var/www/kibana/html/ -r
cp /home/amadmin/box4s/Nginx/etc/nginx/nginx.conf /etc/nginx
cp /home/amadmin/box4s/Nginx/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/
sudo systemctl restart nginx
echo "Update durchgeführt"
