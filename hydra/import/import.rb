#!/bin/env ruby

require "#{Rails.root}/lib/import_library.rb"

class Import
  include ImportLibrary

  def initialize
    puts 'This will import the current export into fedora and solr in your current environment ... are you sure you want to do this? (Yes, No)'
    perform
  end

  def process_json_file(json_file)
    # parse the json file
    @objects = JSON.parse json_file
    # set objects
    @objects.each do |record|
      begin
        # skip record if EXCLUDE is in title
        next if record['title'].include?("EXCLUDE")

        puts "Processing #{record['idno']}"

        # remove . in identifier
        id = record['idno'].gsub('.', '').to_s
        puts "ID: #{id}"

        # record exists
        record_exists = Acda.where(identifier: id).first

        if record_exists.nil?
          puts "Inserting Record (#{record['idno']})"
          ImportLibrary.import_record(id, ImportLibrary.modify_record(@export_path, record))
        else          
          puts "Updating Record (#{record['idno']})"
          ImportLibrary.update_record(record_exists, ImportLibrary.modify_record(@export_path, record))
        end
      rescue RuntimeError => e
        puts "Record (#{record['idno']})"
        abort "Error (#{e})"
      end
    end
  end        

  def parse_data
    # parse the json file  
    @export_path = Dir.glob("/mfcs_export/*").last
    puts "Importing from #{@export_path}"

    # find the json file in the directory
    matched_files = Dir["#{@export_path}/data/*-data.json"]

    if File.exist?(matched_files.first)
      # read and parse the json file
      process_json_file(File.read matched_files[0])
    else
      abort "No data file found"
    end
  end

  def perform
    answer = ImportLibrary.prompt.downcase
    if %w[yes y 1 true].include? answer
      parse_data
      puts "We performed the current import because you answered - #{answer}"
    else
      abort "Import was not performed, your answer was #{answer}"
    end
  end
end

Import.new