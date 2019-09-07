# Helper file for creating tools for creating pre-compiled
# dependencies to be put into PrecompiledDB
# Any file using this must set PrecompiledInstallFolder and create a method:
# getDependencyObjectByName(name) that returns the dependency by name
# also if --all option or creating missing is needed also getAllDependencies
# needs to be implemented

# If you get errors on windows do `ridk install` and try all the 3 options
# then install this gem
require 'sha3'

require 'optparse'
require 'fileutils'

require_relative 'RubyCommon.rb'

require_relative 'PrecompiledDB.rb'

def checkRunFolder(suggested)
  suggested
end

def projectFolder(baseDir)
  baseDir
end

def getExtraOptions(opts)

  if defined? getAllDependencies
    opts.on("--all", "Make packages of all the dependencies") do |b|
      $options[:buildAll] = true
    end

    opts.on("--missing", "Make packages of the dependencies with missing packages") do |b|
      $options[:buildMissing] = true
    end
  end
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

if !$toPackageDeps && !$options[:buildAll] && !$options[:buildMissing]
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

# Packages a single dependency
def packageDependency(dep)
  info "Starting packaging #{dep}"

  if dep.is_a? String
    instance = getDependencyObjectByName dep
  else
    instance = dep
  end

  if !instance
    onError "Invalid dependency name: #{dep}"
  end

  files = instance.getInstalledFiles

  if !files || files.length == 0
    onError "Dependency '#{dep}' has no files to package"
  end

  precompiledName = instance.getNameForPrecompiled + "_" + CurrentPlatform
  zipName = precompiledName + ".7z"
  infoFile = precompiledName + "_info.txt"
  hashFile = precompiledName + "_hash.txt"

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
      f.puts instance.Version.to_s + " Packaged at " + Time.now.to_s
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
    return {name: precompiledName, hash: hash}
  }
end

# Main function for missing
def runPackageForMissing
  puts "Packaging dependencies missing for current platform"

  $usePrecompiled = true

  puts "Making sure databases are loaded..."
  databases = getDefaultDatabases

  if databases
    success "Databases loaded"
  else
    onError "database loading failed"
  end

  created = 0

  getAllDependencies.each{|dep|
    puts "Checking dependency: #{dep.Name}"

    precompiled = getSupportedPrecompiledPackage dep

    if !precompiled
      puts "No precompiled available. Creating package"

      info = packageDependency dep
      puts "Adding to local database instance"
      databases[0].add PrecompiledDependency.new info[:name], databases[0].baseURL, info[:hash]
      created += 1
    end

    puts ""
  }

  puts "Created #{created} new package(s)"

  if created > 0
    updatedDBFile = File.join DependencyInstallFolder, "database.json"
    puts "Writing updated database file: #{updatedDBFile}"
    databases[0].write updatedDBFile
  end
end

# Main function
def runPackager
  puts ""
  puts "Packaging dependencies: #{$toPackageDeps}"
  puts "Target folder: #{DependencyInstallFolder}"

  if $options[:buildMissing]
    runPackageForMissing
  else
    if $options[:buildAll]
      info "Packaging all dependencies"

      $toPackageDeps = []

      getAllDependencies().each{|dep|
        files = dep.getInstalledFiles

        if files && files.length > 0
          $toPackageDeps.push dep.Name
        end
      }

      puts "#{$toPackageDeps}"
    end

    $toPackageDeps.each{|dep|
      packageDependency dep
    }
  end

  puts ""
  success "Done creating."
  puts "Make sure everything was up to date before distributing."
  true
end
