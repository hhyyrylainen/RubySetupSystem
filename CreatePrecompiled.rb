# Tool for creating pre-compiled dependencies to be put into PrecompiledDB
require 'optparse'
require 'fileutils'

require_relative 'RubyCommon.rb'

require_relative 'PrecompiledDependency.rb'
require_relative 'PrecompiledDB.rb'

def checkRunFolder(suggested)

  doxyFile = File.join(suggested, "CreatePrecompiled.rb")

  onError("Not ran from RubySetupSystem folder!") if not File.exist?(doxyFile)

  return File.expand_path File.join(suggested, "../")
end

def projectFolder(baseDir)

  baseDir
  
end


def getExtraOptions(opts)

  opts.on("--install-folder path", "The folder to look for the compiled binaries in " +
                                   "for CreatePrecompiled. Default: 'build/ThirdParty'") do |p|
    $options[:precompiledInstallFolder] = true
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

# Read extraOptions
DependencyInstallFolder = File.join(CurrentDir, if $options[:precompiledInstallFolder]
                                    $options[:precompiledInstallFolder] else
                                     "build/ThirdParty"
                                    end
                                   )

if !$toPackageDeps
  onError("CreatePrecompiled: expected a list of dependencies to package, " +
          "instead got nothing")
end

info "This is RubySetupSystem precompiled dependency packager"
info "Current platform is #{describePlatform}"

puts ""

if !File.exist? DependencyInstallFolder
  onError "Didn't find dependency install folder '#{DependencyInstallFolder}'"
end

puts "Finding precompiled binaries in: #{DependencyInstallFolder}"

puts ""
puts "Packaging dependencies: #{$toPackageDeps}"

exit 1
success "Done creating. Make sure everything was up to date before distributing"
exit 0





