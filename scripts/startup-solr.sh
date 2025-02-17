#!/bin/bash

# set terminal 
export TERM=vt100

cp -r /opt/solr/modules/extraction/lib/* /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/
cp -r /opt/solr/modules/analysis-extras/lib/* /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/

mkdir -p /var/solr/data/$1
cp -r /solr9-setup/conf /var/solr/data/$1/conf
cp /solr9-setup/core.properties /var/solr/data/$1
cp /solr9-setup/security.json /var/solr/data
chown -R 8983:8983 /var/solr
runuser -u solr -- solr start -f