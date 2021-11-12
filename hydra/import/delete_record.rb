#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora'

# get the identifier 
puts "Please enter the identifer of the object you want to destroy"
id = gets.to_s.strip!

# delete the project
Acda.where(identifier: id).first.destroy
puts "Removed #{id} from the fedora and solr."