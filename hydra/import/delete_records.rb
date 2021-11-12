#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora'

# get the identifier 
puts "Are you sure you want to delete all the records?"
answer = gets.to_s
answer.downcase!
answer.strip!

if (answer == 'y' || answer == 'yes' || answer == true || answer == 1)
  # delete the records in fedora and solr
  Acda.all.each do |record|
    begin
      id = record.id

      # delete record from fedora
      record.destroy

      # delete tombstone for record
      ActiveFedora::Base.eradicate(id)
      puts "Deleted Record (#{id})"
    end
  end
  puts "Destroyed all acda Records"
else 
  puts "Aborted."
end 