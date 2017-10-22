# This file is a template on how to make sure that RubySetupSystem can
# be easily loaded from a git submodule

# RubySetupSystem Bootstrap
if not File.exists? "RubySetupSystem/RubySetupSystem.rb"
  puts "Initializing RubySetupSystem"
  system "git submodule init && git submodule update --recursive"

  if $?.exitstatus != 0
    abort("Failed to initialize or update git submodules. " +
          "Please make sure git is in path and running 'git submodule init' works.")
  end
end
