#!/bin/bash

# install yarn packages
yarn install --check-files

# set terminal 
export TERM=vt100

# start cron and update whenever 
service cron start
whenever --update-crontab

# remove PID and start the server
rm -f /home/hydra/tmp/pids/server.pid

bin/rails s -p 3000 -b '0.0.0.0'