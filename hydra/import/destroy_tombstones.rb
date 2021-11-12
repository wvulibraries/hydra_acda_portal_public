
# get a file to get all the ID's from. 
require 'json'

@export_path = Dir.glob("/mfcs_export/*").last
puts "Destroying Tombstones from #{@export_path}"

# find the json file in the directory
json_file = Dir["#{@export_path}/data/*-data.json"][0]

if File.exist?(json_file)
  # read and parse the json file
  objects = JSON.parse(File.read json_file)

  idnos = objects.map{ |x| x['idno'] }
  idnos.each do |idno| 
    result = Acda.eradicate(idno)
    puts "Result of eradication on #{idno} was #{result} \n"
  end 
else
  abort "No data file found"
end

