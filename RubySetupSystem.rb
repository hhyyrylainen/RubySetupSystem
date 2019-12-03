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
  # opts.banner = "Usage: Setup.rb [OPTIONS]"

  opts.on('--[no-]sudo', 'Run commands that need sudo. ' \
                         'This may be needed to run successfuly') do |b|
    $options[:sudo] = b
  end
  opts.on('--only-project', 'Skip all dependencies setup') do |_b|
    $options[:onlyProject] = true
  end

  opts.on('--no-subproject-deps', "Don't setup dependencies in a subproject " \
                                  '(that uses RubySetupSystem)') do |_b|
    $options[:noSubProjectDeps] = true
  end

  opts.on('--only-deps', 'Skip the main project setup') do |_b|
    $options[:onlyDeps] = true
  end

  # TODO: should this be passed to sub setups
  opts.on('--only-dep a,b,c', Array, 'Only setup the specified dependencies') do |list|
    $options[:only] = list
  end

  # TODO: should this be passed to sub setups
  opts.on('--skip-dep a,b,c', Array, 'Skip setting up the specified dependencies') do |list|
    $options[:skip] = list
  end

  opts.on('--no-packagemanager', 'Skip using the system package manager ' \
                                 'to download libraries') do |_b|
    $options[:noPackager] = true
  end

  opts.on('--pretend-linux OS', 'Pretend that setup is ran on specified Linux OS. ' \
                                "A good choice is 'fedora' for getting package names if " \
                                "your OS isn't supported by this setup") do |os|
    $pretendLinux = os
  end

  opts.on('--no-updates', 'Skips downloading dependencies / making sure they ' \
                          'are up to date') do |_b|
    $options[:noUpdates] = true
  end

  opts.on('-j threads', '--parallel-compiles threads',
          'Number of simultaneous compiler instances to run') do |j|
    $options[:parallel] = j.to_i
  end

  opts.on('--fully-parallel-project-compile',
          'Even if not all cores are used for compiling dependencies (-j flag) the main ' \
          'project is compiled with all cores') do |_b|
    $options[:projectFullParallel] = true
  end

  opts.on('--project-parallel threads',
          'Restricts fully parallel project compile to specific number of threads') do |t|
    $options[:projectFullParallelLimit] = t.to_i
  end

  opts.on('--[no-]precompiled', 'Run with or without precompiled dependencies') do |b|
    $options[:precompiled] = b
  end

  opts.on('-h', '--help', 'Show this message') do
    puts opts
    puts extraHelp if defined? extraHelp
    exit
  end

  # If you want to add flags they need to be in this method instead of parseExtraArgs
  getExtraOptions opts if defined? getExtraOptions
end.parse!

unless ARGV.empty?
  # Let application specific args to be parsed
  parseExtraArgs if defined? parseExtraArgs

  unless ARGV.empty?

    onError('Unkown arguments. See --help. This was left unparsed: ' + ARGV.join(' '))

  end
end

### Setup variables
CMakeBuildType = 'RelWithDebInfo'.freeze
$compileThreads = $options.include?(:parallel) ? $options[:parallel] : Etc.nprocessors

if $compileThreads > Etc.nprocessors
  $compileThreads = Etc.nprocessors
  puts "Limiting parallel compile to detected number of CPU cores: #{$compileThreads}"
end

# If set to false won't install libs that need sudo
DoSudoInstalls = $options.include?(:sudo) ? $options[:sudo] : true

# If true dependencies won't be updated from remote repositories
SkipPullUpdates = $options[:noUpdates] ? true : false

# If true skips all dependencies
OnlyMainProject = $options[:onlyProject] ? true : false

# If true skips the main project
OnlyDependencies = $options[:onlyDeps] ? true : false

# If specified only deps on this list are ran (case insensitive)
OnlySpecificDeps = $options[:only] || nil

# If specified these dependencies are skipped (case insensitive)
NoSpecificDeps = $options[:skip] || nil

# If true skips running package installs
SkipPackageManager = $options[:noPackager] ? true : false

# If true new version of depot tools and breakpad won't be fetched on install
NoBreakpadUpdateOnWindows = false

# This is either true, false, or "ask" (if not interactive ask turns to false)
# Not constant as this is changed by getSupportedPrecompiledPackage after asking the user
$usePrecompiled = if $options.include?(:precompiled)
                    if $options[:precompiled]
                      true
                    else
                      false
                    end
                  else
                    if !$stdout.isatty
                      warning '--[no-]precompiled parameter give and not running in' \
                              'interactive terminal, disabling precompiled'
                      false
                    else
                      'ask'
                    end
                  end

# On windows visual studio will be automatically opened if required
AutoOpenVS = true

# Set tool chain
TC = if OS.windows?
       # Leviathan needs by default vs 2017
       WindowsMSVC.new(VisualStudio2017.new)
     elsif OS.linux?
       LinuxNative.new
     else
       onError 'No toolchain configured for this platform!'
     end

# TODO: create a variable for running the package manager on linux if possible
puts "Using toolchain: #{TC.name}"

### Commandline handling
# TODO: add this

if OS.linux?
  HasDNF = !which('dnf').nil?

  info "Pretending that current Linux OS is: #{$pretendLinux}" if $pretendLinux
else
  HasDNF = false
end

# This verifies that CurrentDir is good and assigns it to CurrentDir
CurrentDir = checkRunFolder Dir.pwd

ProjectDir = projectFolder CurrentDir

# This function formats the current options like threads etc. to be
# passed to a dependency that also uses RubySetupSystem
# example of use: system("ruby Setup.rb #{passOptionsToSubRubySetupSystemProject}")
# Note: the unsafe system call needs to be used as the child project might want user input as
# for precompiled selection etc.
def passOptionsToSubRubySetupSystemProject
  opts = []
  unless $usePrecompiled.nil?
    if $usePrecompiled == false
      opts.push '--no-precompiled'
    elsif $usePrecompiled == true
      opts.push '--precompiled'
    end
  end

  opts.push "-j #{$options[:parallel]}" if $options.include?(:parallel)

  if $options.include?(:sudo)
    if $options[:sudo]
      opts.push '--sudo'
    else
      opts.push '--no-sudo'
    end
  end

  opts.push '--no-packagemanager' if $options.include?(:noPackager)

  opts.push '--no-updates' if $options.include?(:noUpdates)

  # This option is handled here (translated to the right option)
  opts.push '--only-project' if $options.include?(:noSubProjectDeps)

  if $pretendLinux
    opts.push '--pretend-linux'
    opts.push $pretendLinux
  end

  opts
end

#
# Initial options / status print
#

info "Running in dir '#{CurrentDir}'"
puts "Project dir is '#{ProjectDir}'"

info 'Using dnf package manager' if HasDNF

puts "Using #{$compileThreads} threads to compile, configuration: #{CMakeBuildType}"

if $options.include?(:projectFullParallel)
  puts "Main project uses all cores (#{Etc.nprocessors})"
  if $options.include?(:projectFullParallelLimit)
    if $options[:projectFullParallelLimit] > Etc.nprocessors
      puts 'Limiting project parallel to number of detected CPU cores.'
      $options[:projectFullParallelLimit] = Etc.nprocessors
    end
    puts "With extra limit set to #{$options[:projectFullParallelLimit]}"
  end
end

puts "With use precompiled set to: #{$usePrecompiled}"

# Set required environment variables with the tool chain
# Most toolchains don't need this
TC.setupEnv

puts ''
puts ''

require_relative 'Installer.rb'
require_relative 'RubyCommon.rb'
require_relative 'WindowsHelpers.rb'
require_relative 'CustomInstaller.rb'

# Returns true if sudo should be enabled
def shouldUseSudo(localOption, warnIfMismatch = true)
  if localOption

    unless DoSudoInstalls

      if warnIfMismatch

        warning "Sudo is globally disabled, but a command should be ran as sudo.\n" \
                'If something breaks please rerun with sudo allowed.'
      end

      return false

    end

    return true

  end

  false
end

# Returns "sudo" or "" based on options
def getSudoCommand(localOption, warnIfMismatch = true)
  return '' unless shouldUseSudo localOption, warnIfMismatch

  'sudo '
end

require_relative 'LibraryCopy.rb'

require_relative 'Dependency.rb'

# Library installs are now in separate files in the Libraries sub directory
