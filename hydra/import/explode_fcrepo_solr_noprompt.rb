#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora/cleaner'

class DestroyFedoraSolr
  def initialize
    destroy
  end

  def destroy
    answer = 'yes'
    if answer == 'yes' || answer == 'y' || answer == '1' || answer == 'true'
      ActiveFedora::Cleaner.clean!
      puts "The contents of Fedora and Solr have been destroyed."
    else
      abort "Cleaning was not done."
    end
  end
end

delete = DestroyFedoraSolr.new
