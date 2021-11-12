#!/bin/bash

# set terminal 
export TERM=vt100

service cron start

# https://github.com/avitase/docker-imagemagick/blob/master/fixpolicy.sh
# code to adjust policy so imagemagic can covert pdf files correctly

policy="$(ls -1 /etc/ImageMagick-*/policy.xml | head -n1)"
if [ ! -f $policy ]; then
    echo "policy.xml not found!"
    exit 1
fi

line="$(grep -n '<policy domain="coder" rights="none" pattern="PDF" />' $policy)"

if [ ! -z "$line" ]; then
    n="$(echo $line | cut -f1 -d:)"
    sed -i "${n}s/rights=\"none\"/rights=\"read\|write\"/" $policy
fi

# keep container from closing
tail -f /dev/null