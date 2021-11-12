#!/bin/bash

path="${@}"
image_folder="pdfimages"
thumb_folder="pdfthumbs"

# create image folder
if [ -d "${path}"/"${image_folder}" ]; then
  rm "${path}/${image_folder}"/*
else
  mkdir -p "${path}/${image_folder}"
fi

# create thumbnail folder
if [ -d "${path}"/"${thumb_folder}" ]; then
  rm "${path}/${thumb_folder}"/*
else
  mkdir -p "${path}/${thumb_folder}"
fi

for f in "${path}"/pdf/*.pdf
do 
  filename=$(basename -- "$f")
  extension="${filename##*.}"
  filename="${filename%.*}"

  convert -background white -alpha remove "$f"[0] "${path}/${image_folder}/${filename%}.jpg"

  convert -thumbnail 150x -background white -alpha remove "$f"[0] "${path}/${thumb_folder}/${filename%}.jpg"
done