# coding: utf-8
# A ruby script for downloading and installing C++ project dependencies
# Made by Henri Hyyryläinen

require_relative 'RubyCommon.rb'
require_relative 'DepGlobber.rb'

require_relative 'ToolChain.rb'
require_relative 'VSVersion.rb'

require_relative 'PrecompiledDB.rb'

require 'optparse'
require 'fileutils'
require 'etc'
require 'os'
require 'open3'
require 'pathname'
require 'zip'

#
# Parse options
#

$options = {}
OptionParser.new do |opts|
  # Default banner is fine, scripts calling this can add their options and their banners
  # will be correct. See DockerImageCreator.rb for an example
  #opts.banner = "Usage: Setup.rb [OPTIONS]"

  opts.on("--[no-]sudo", "Run commands that need sudo. " +
                         "This may be needed to run successfuly") do |b|
    $options[:sudo] = b
  end 
  opts.on("--only-project", "Skip all dependencies setup") do |b|
    $options[:onlyProject] = true
  end

  opts.on("--only-deps", "Skip the main project setup") do |b|
    $options[:onlyDeps] = true
  end

  opts.on("--no-packagemanager", "Skip using the system package manager " +
                                 "to download libraries") do |b|
    $options[:noPackager] = true
  end

  opts.on("--no-updates", "Skips downloading dependencies / making sure they "+
                          "are up to date") do |b|
    $options[:noUpdates] = true
  end

  opts.on("-j threads", "--parallel-compiles threads",
          "Number of simultaneous compiler instances to run") do |j|
    $options[:parallel] = j.to_i
  end

  opts.on("--fully-parallel-project-compile",
          "Even if not all cores are used for compiling dependencies (-j flag) the main " +
          "project is compiled with all cores") do |b|
    $options[:projectFullParallel] = true
  end

  opts.on("--project-parallel threads",
          "Restricts fully parallel project compile to specific number of threads") do |t|
    $options[:projectFullParallelLimit] = t.to_i
  end  

  opts.on("--[no-]precompiled", "Run with or without precompiled dependencies") do |b|
    $options[:precompiled] = b
  end 

  opts.on("-h", "--help", "Show this message") do
    puts opts
    if defined? extraHelp
      puts extraHelp
    end
    exit
  end

  # If you want to add flags they need to be in this method instead of parseExtraArgs
  if defined? getExtraOptions
    getExtraOptions opts
  end
  
end.parse!

if !ARGV.empty?
  # Let application specific args to be parsed
  if defined? parseExtraArgs
    parseExtraArgs
  end

  if !ARGV.empty?

    onError("Unkown arguments. See --help. This was left unparsed: " + ARGV.join(' '))

  end
end

### Setup variables
CMakeBuildType = "RelWithDebInfo"
$compileThreads = if $options.include?(:parallel) then $options[:parallel] else
                    Etc.nprocessors end

# If set to false won't install libs that need sudo
DoSudoInstalls = if $options.include?(:sudo) then $options[:sudo] else true end

# If true dependencies won't be updated from remote repositories
SkipPullUpdates = if $options[:noUpdates] then true else false end

# If true skips all dependencies
OnlyMainProject = if $options[:onlyProject] then true else false end

# If true skips the main project
OnlyDependencies = if $options[:onlyDeps] then true else false end

# If true skips running package installs
SkipPackageManager = if $options[:noPackager] then true else false end

# If true new version of depot tools and breakpad won't be fetched on install
NoBreakpadUpdateOnWindows = false

# This is either true, false, or "ask" (if not interactive ask turns to false)
UsePrecompiled = if $options.include?(:precompiled)
                   if $options[:precompiled]
                     true
                   else
                     false
                   end
                 else
                   if !$stdout.isatty
                     warning "--[no-]precompiled parameter give and not running in" +
                             "interactive terminal, disabling precompiled"
                     false
                   else
                     "ask"
                   end
                 end

# On windows visual studio will be automatically opened if required
AutoOpenVS = true

# Set tool chain
TC = if OS.windows?
       # Leviathan needs by default vs 2017
       WindowsMSVC.new(VisualStudio2017.new)
     elsif OS.linux?
       LinuxNative.new()
     else
       onError "No toolchain configured for this platform!"
     end

# TODO create a variable for running the package manager on linux if possible

### Commandline handling
# TODO: add this

if OS.linux?
  HasDNF = which("dnf") != nil
  
  # Fail if lsb_release is missing
  if which("lsb_release") == nil

    onError "lsb_release is missing, please install it."
  end
  
else
  HasDNF = false
end


# This verifies that CurrentDir is good and assigns it to CurrentDir
CurrentDir = checkRunFolder Dir.pwd

ProjectDir = projectFolder CurrentDir

#
# Initial options / status print
#

info "Running in dir '#{CurrentDir}'"
puts "Project dir is '#{ProjectDir}'"

if HasDNF
  info "Using dnf package manager"
end

puts "Using #{$compileThreads} threads to compile, configuration: #{CMakeBuildType}"

if $options.include?(:projectFullParallel)
  puts "Main project uses all cores (#{Etc.nprocessors})"
  if $options.include?(:projectFullParallelLimit)
    puts "With extra limit set to #{$options[:projectFullParallelLimit]}"
  end
end

puts "With use precompiled set to: #{UsePrecompiled}"

# Set required environment variables with the tool chain
# Most toolchains don't need this
TC.setupEnv

puts ""
puts ""

require_relative "Installer.rb"
require_relative "RubyCommon.rb"
require_relative "WindowsHelpers.rb"
require_relative 'CustomInstaller.rb'

# Returns true if sudo should be enabled
def shouldUseSudo(localOption, warnIfMismatch = true)

  if localOption

    if !DoSudoInstalls

      if warnIfMismatch

         warning "Sudo is globally disabled, but a command should be ran as sudo.\n" +
                 "If something breaks please rerun with sudo allowed."
      end

      return false
      
    end

    return true
    
  end

  return false
end

# Returns "sudo" or "" based on options
def getSudoCommand(localOption, warnIfMismatch = true)

  if(!shouldUseSudo localOption, warnIfMismatch)
    return ""
  end
  
  return "sudo "
end

require_relative "LibraryCopy.rb"

require_relative "Dependency.rb"

# Library installs are now in separate files in the Libraries sub directory



