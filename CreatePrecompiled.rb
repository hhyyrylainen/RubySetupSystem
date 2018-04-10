# Helper file for creating tools for creating pre-compiled
# dependencies to be put into PrecompiledDB
# Any file using this must set PrecompiledInstallFolder and create a method:
# getDependencyObjectByName(name) that returns the dependency by name

# If you get errors on windows do `ridk install` and try all the 3 options
# then install this gem
require 'sha3'

require 'optparse'
require 'fileutils'

require_relative 'RubyCommon.rb'

require_relative 'PrecompiledDependency.rb'
require_relative 'PrecompiledDB.rb'

def checkRunFolder(suggested)
  suggested
end

def projectFolder(baseDir)
  baseDir
end

def extraHelp
  puts "CreatePrecompiled: tool for packaging binaries for others to download " +
       "using RubySetupSystem"
end

def parseExtraArgs
  $toPackageDeps = ARGV.dup
  ARGV.clear
end

require_relative 'RubySetupSystem.rb'

# Programming error
raise AssertionError unless PrecompiledInstallFolder

# Read extraOptions
DependencyInstallFolder = File.join(CurrentDir, PrecompiledInstallFolder)

if !$toPackageDeps
  onError("CreatePrecompiled: expected a list of dependencies to package, " +
          "instead got nothing")
end

if !File.exist? DependencyInstallFolder
  onError "Didn't find dependency install folder '#{DependencyInstallFolder}'"
end


info "This is RubySetupSystem precompiled dependency packager"
info "Current platform is #{describePlatform}"

puts ""
puts "Finding precompiled binaries in: #{DependencyInstallFolder}"
puts ""

CurrentPlatform = describePlatform

# Main function
def runPackager
  puts ""
  puts "Packaging dependencies: #{$toPackageDeps}"

  $toPackageDeps.each{|dep|

    info "Starting packaging #{dep}"

    instance = getDependencyObjectByName dep

    if !instance
      onError "Invalid dependency name: #{dep}"
    end

    files = instance.getInstalledFiles

    if !files || files.length == 0
      onError "Dependency '#{dep}' has no files to package"
    end

    zipName = instance.getNameForPrecompiled + "_" + CurrentPlatform + ".7z"
    infoFile = instance.getNameForPrecompiled + "_" + CurrentPlatform + "_info.txt"
    hashFile = instance.getNameForPrecompiled + "_" + CurrentPlatform + "_hash.txt"
    
    # Check that all exist
    Dir.chdir(DependencyInstallFolder){

      files.each{|f|

        if !File.exists? f
          onError "Dependency file that should be packaged doesn't exist: #{f}"
        end
      }

      File.open(infoFile, 'w') {|f|
        f.puts "RubySetupSystem precompiled library for #{CurrentPlatform}"
        f.puts instance.Name + " retrieved from " + instance.RepoURL
        f.puts instance.Version + " Packaged at " + Time.now.to_s
        f.puts ""
        f.puts "You can probably find license from the repo url if it isn't included here"
        f.puts "This info file is included in " + zipName
      }
      
      runSystemSafe(*[p7zip, "a", zipName, infoFile, files].flatten)

      if !File.exists? zipName
        onError "Failed to create zip file"
      end

      hash = SHA3::Digest::SHA256.file(zipName).hexdigest

      # Write hash to file
      File.open(hashFile, 'w') {|f|
        f.puts hash
      }

      success "Done with #{dep}, created: #{zipName}"
      info "#{zipName} SHA3: " + hash
      # info "#{zipName} PLATFORM: " + CurrentPlatform
    }
  }

  puts ""
  success "Done creating."
  puts "Make sure everything was up to date before distributing."
  true
end







