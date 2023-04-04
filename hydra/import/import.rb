#!/bin/env ruby

require "#{Rails.root}/lib/import_library.rb"

# Import Class
# =====================================================
# This class will import the current export into fedora and solr in your current environment
# =====================================================
# Usage:
#   bin/rails r import/import.rb
# =====================================================
# Author: Tracy A. McCormick
# Modified: 2023-03-13
# =====================================================

class Import
  include ImportLibrary

  def initialize
    # init variables
    @project_name = "acda_portal_public"
    @export_path = "/mnt/nfs-exports/mfcs-exports/#{@project_name}/export"

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

        # add file to item job queue
        ImportRecordJob.perform_later(@export_path, record)        
      rescue RuntimeError => e
        puts "Record (#{record['idno']})"
        abort "Error (#{e})"
      end
    end
  end        

  def parse_data
    # parse the json file  
    @path = Dir.glob("#{@export_path}/*").last
    puts "Importing from #{@path}"

    # find the json file in the directory
    matched_files = Dir["#{@path}/data/*-data.json"]

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