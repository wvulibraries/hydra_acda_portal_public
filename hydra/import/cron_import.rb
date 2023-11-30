# grab the arguments passed in by the script
project_name = ARGV[0]

# abort if the 
abort "Missing project name" if project_name.nil? 
control_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/mfcs"
process_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/in-progress"

# if there is already a control file in the processing directory, exit
if Dir.entries(process_dir).length > 2
  puts "processing already in process"
  exit
end

Dir.open(control_dir).sort.each do |file|
  next if file == '.' || file == '..'
  control_file = YAML.load_file "#{control_dir}/#{file}"
  AutomaticImportJob.perform_now control_file
  break
end