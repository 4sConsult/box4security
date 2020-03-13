docker run -d -p 3030:3030 -p 3333:3333 \
    -v `pwd`/config/elastalert.yaml:/opt/elastalert/config.yaml \
    -v `pwd`/config/elastalert-test.yaml:/opt/elastalert/config-test.yaml \
    -v `pwd`/config/config.json:/opt/elastalert-server/config/config.json \
    -v `pwd`/rules:/opt/elastalert/rules \
    -v /etc/msmtp:/etc/msmtp \
    -v /etc/aliases:/etc/aliases \
    -v `pwd`/rule_templates:/opt/elastalert/rule_templates \
    --net="host" \
    --name elastalert elastalert:latest
