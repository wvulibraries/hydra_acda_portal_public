#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora'

# get the identifier 
puts "Are you sure you want to delete the entire project?"
answer = gets.to_s
answer.downcase!
answer.strip!

if (answer == 'y' || answer == 'yes' || answer == true || answer == 1)
  # delete the project
  ActiveFedora::Base.where(project_tesim: '%%abbr%%').destroy_all
  puts "Destroyed the project -- %%abbr%%"
else 
  puts "Aborted."
end 