#!/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora/cleaner'

class DestroyFedoraSolr
  def initialize
    puts 'This will remove contents of fedora and solr in your current environment ... are you sure you want to do this? (Yes, No)'
    destroy
  end

  def prompt
    result = gets.to_s
    result.downcase!
    result.strip!
    result.empty? ? 'no' : result
  end

  def destroy
    answer = prompt
    if answer == 'yes' || answer == 'y' || answer == '1' || answer == 'true'
      ActiveFedora::Cleaner.clean!
      puts "We destroyed that thing because you answered - #{answer}"
    else
      abort "Nothing changed and cleaning was not done, your answer was #{answer}"
    end
  end
end

delete = DestroyFedoraSolr.new
