#!/bin/bash
# remove docker volumes
docker volume prune --all --force
# remove contents of ./data/logs
rm -rf ./data/logs/*
# remove solr data directory
rm -rf ./data/solr
# remove postgres data directory
rm -rf ./data/postgres
# remove fcrepo data directory
rm -rf ./data/fcrepo