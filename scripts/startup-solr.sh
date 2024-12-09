#!/bin/bash

# set terminal 
export TERM=vt100

chown -R 8983:8983 /var/solr
mkdir -p /var/solr/data/$1
cp -r /solr9-setup/conf /var/solr/data/$1/conf
cp /solr9-setup/core.properties /var/solr/data/$1
cp /solr9-setup/security.json /var/solr/data
runuser -u solr -- solr start -f