require 'fileutils'

# grab the arguments passed in by the script 
project_name = ARGV[0]

# abort if the 
abort "Missing project name" if project_name.nil? 
control_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/mfcs"
process_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/in-progress"
process_finished_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/finished"
process_failed_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/failed"
conversion_process_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/conversion/in-progress"
conversion_finished_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/conversion/finished"
export_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/export"

# create the directories if they don't exist
FileUtils.mkdir_p(control_dir) unless File.exist?(control_dir)
FileUtils.mkdir_p(process_dir) unless File.exist?(process_dir)
FileUtils.mkdir_p(process_finished_dir) unless File.exist?(process_finished_dir)
FileUtils.mkdir_p(process_failed_dir) unless File.exist?(process_failed_dir)
FileUtils.mkdir_p(conversion_process_dir) unless File.exist?(conversion_process_dir)
FileUtils.mkdir_p(conversion_finished_dir ) unless File.exist?(conversion_finished_dir )
FileUtils.mkdir_p(export_dir) unless File.exist?(export_dir)

# if there is already a control file in the conversion directory, exit
if Dir.entries(conversion_process_dir).length > 2
  puts "conversion in process skipping"
  exit 
end 

# if there is already a control file in the processing directory, exit
if Dir.entries(process_dir).length > 2
  puts "processing already in process"
  exit 
end 

# open the control directory and sort the files
puts "opening control directory #{control_dir}"
Dir.open(control_dir).sort.each do |file|
  next if file == '.' || file == '..'
  control_file = YAML.load_file "#{control_dir}/#{file}"
  # if the control file is not in the finished conversion directory, skip import
  next if !File.exist?("#{conversion_finished_dir}/#{File.basename(file).split('.')[0]}")
  AutomaticImportJob.perform_now control_file
  break
end