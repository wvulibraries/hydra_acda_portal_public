#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora'

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
