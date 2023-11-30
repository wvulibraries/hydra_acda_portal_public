#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora'

# get the identifier 
puts "Are you sure you want to delete #{Rails.env} ACDA?"
answer = gets.to_s
answer.downcase!
answer.strip!

if (answer == 'y' || answer == 'yes' || answer == true || answer == 1)
  # delete the project
  ActiveFedora::Base.where(project_tesim: 'acda').each { |r| r.delete(eradicate: true) }
  puts 'Destroyed the project -- ACDA'
else 
  puts "Aborted."
end 