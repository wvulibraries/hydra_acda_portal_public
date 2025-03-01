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
# remove exports directory
rm -rf ./data/exports
# remove images directory
rm -rf ./data/images
# remove imports directory
rm -rf ./data/imports
# remove pdfs directory
rm -rf ./data/pdf
# remove thumbnails directory
rm -rf ./data/thumbnails
# remove tmp directory
rm -rf ./data/tmp
# remove logs validations directory
rm -rf ./data/logs/validations