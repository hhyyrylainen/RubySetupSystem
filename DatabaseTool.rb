#!/usr/bin/env ruby
# Tool for doing things with the RubySetupSystem databases
require_relative 'RubyCommon'
require_relative 'PrecompiledDB'
require_relative 'Database/Database'

require 'optparse'


#
# Parse options
#

$options = {}
OptionParser.new do |opts|

  opts.on("-i", "--info", "Show information about databases") do |b|
    $options[:info] = true
  end

  opts.on("-f", "--find name", "Find a precompiled dependency containing name") do |n|
    $options[:find] = n
  end

  opts.on("-l", "--download name", "Download a precompiled library with name") do |n|
    $options[:dl] = n
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  
end.parse!

if !ARGV.empty?
  # Handle extra args 

  if !ARGV.empty?

    onError("Unkown arguments. See --help. This was left unparsed: " + ARGV.join(' '))
  end
end

if $options[:info]
  getDefaultDatabases.each{|db|
    db.info
    puts ""
  }
elsif $options[:find]
    getDefaultDatabases.each{|db|
      db.search($options[:find]).each{|dep|
        puts dep
      }

    }
elsif $options[:dl]

  precompiled = getPrecompiledByName $options[:dl]

  onError "no library with specified name found" if !precompiled

  precompiled.download precompiled.ZipName

else
  onError "No operation specified. Use -h to see help"
end
