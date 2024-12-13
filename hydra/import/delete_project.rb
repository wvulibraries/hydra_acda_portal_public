#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora'

# This script will delete all records with the project identifier 'mcppc'
# This is a destructive operation and should be used with caution
# This script will prompt the user for confirmation before deleting the records

# set project
project = 'acda'

# get the identifier 
puts "Are you sure you want to delete #{Rails.env} #{project}?"
answer = gets.to_s
answer.downcase!
answer.strip!

if (answer == 'y' || answer == 'yes' || answer == true || answer == 1)
  # delete the project
  # records = ActiveFedora::Base.where(project_tesim: project)
  records = ActiveFedora::Base.all
  if records.any?
    records.each { |r| r.delete(eradicate: true) }
      puts "Destroyed the project -- #{project}"
    else
      puts "No records found for project -- #{project}"
    end
    puts "Destroyed the project -- #{project}"
else 
  puts "Aborted."
end