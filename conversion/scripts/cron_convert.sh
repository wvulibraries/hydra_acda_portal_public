#!/bin/bash

project_name="acda_portal"

# if automatic export folder present set correct paths
if [ -d "/mnt/nfs-exports/mfcs-exports/${project_name}/export" ]; then
    export_path="/mnt/nfs-exports/mfcs-exports/${project_name}/export"
    process_dir="/mnt/nfs-exports/mfcs-exports/${project_name}/control/conversion/in-progress"
    finished_dir="/mnt/nfs-exports/mfcs-exports/${project_name}/control/conversion/finished"
# if automatic export folder not present set manual paths
else
    export_path="/mfcs_export"
    process_dir="/control/in-progress"
    finished_dir="/control/finished"  
fi

for directory in "${export_path}"/*
do
  current_dir=$(basename -- "$directory")
  timestamp="${current_dir##*_}"
  path="${export_path}/${current_dir}"

  # do not run if folder is already converted
  if [ ! -f "$finished_dir/$timestamp" ]; then
    # create control file for conversion
    touch "${process_dir}/${timestamp}"

    # if pdf folder present
    if [ -d "${path}/pdf" ]; then
      bash /convert/create_pdf_images.sh ${path}
    fi

    # if video folder present
    if [ -d "${path}/video" ]; then
      bash /convert/create_video_images.sh ${path}
    fi

    mv $process_dir/$timestamp $finished_dir/$timestamp
  fi
  rm -f $process_dir/*
done



