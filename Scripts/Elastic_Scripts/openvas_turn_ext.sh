cd /lib/systemd/system
sed -e 's/127.0.0.1/0.0.0.0/g' greenbone-security-assistant.service openvas-manager.service openvas-scanner.service
sed -e 's/127.0.0.1/0.0.0.0/g' greenbone-security-assistant.service openvas-manager.service openvas-scanner.service -i
systemctl daemon-reload
systemctl restart openvas
service  greenbone-security-assistant restart
service openvas-manager restart
netstat -tulpn
