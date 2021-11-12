#!/bin/bash

path="${@}"
image_folder="videoimages"
thumb_folder="videothumbs"

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

for f in "${path}"/video/*.*
do 
  filename=$(basename -- "$f")
  extension="${filename##*.}"
  filename="${filename%.*}"

  # extract image from one second into video file
  ffmpeg -i "$f" -ss 00:00:01.000 -vframes 1 "${path}/${image_folder}/${filename%}-extracted.jpg"

  # create image
  convert -resize 800x "${path}/${image_folder}/${filename%}-extracted.jpg" "${path}/${image_folder}/${filename%}.jpg"

  # create thumbnail image
  convert -thumbnail 150x -background white -alpha remove "${path}/${image_folder}/${filename%}-extracted.jpg" "${path}/${thumb_folder}/${filename%}.jpg"

  # remove temp image
  rm "${path}/${image_folder}/${filename%}-extracted.jpg"
done
