#!/usr/bin/env ruby

require 'find'

if File.exists? "RunCodeIndexing.rb"
  runFolder = "../"
else
  runFolder = "./"
end

Dir.chdir(runFolder){

  file_paths = []
  Find.find('.') do |path|

    if path !~ /\.h(pp)?$/ and path !~ /\.cpp$/
      next
    end

    # Special case, installed third party header
    if path =~ /\/build\/ThirdParty\/include/i

    # Another special case, leviathan folder
    elsif path =~ /\/ThirdParty\/leviathan\//i
      
    else

      if path =~ /\/Build\//i or
        path =~ /\/Staging\//i or
        path =~ /\/cmake_build\//i or
        path =~ /\/\.\w+\//i or
        # third party folder might be wanted sometimes so
        # TODO: option to disable this check
        path =~ /\/ThirdParty\//i
        next
      end
    end
    
    file_paths << path 
  end

  puts "Indexing #{file_paths.length} files"

  File.open("cscope.files", "w") do |f|
    f.puts(file_paths)
  end

  system "cscope -b"
}
