# Helpers for creating packaging scripts for projects
require 'sha3'
require "fileutils"

require_relative 'RubyCommon.rb'


def checkRunFolder(suggested)

  buildFolder = File.join(suggested, "build")

  onError("Not ran from base folder (no build directory exists)") if
    not File.exist?(buildFolder)

  target = File.join suggested, "build"

  target

end

def projectFolder(baseDir)

  File.expand_path File.join(baseDir, "../")

end

def getExtraOptions(opts)

  opts.on("--development", "Allow making development, -DMAKE_RELEASE=0, builds") do |b|
    $options[:allowDevelopment] = true
  end

end

def extraHelp
  puts $extraParser
end

require_relative 'RubySetupSystem.rb'

SymbolTarget = File.join(CurrentDir, "Symbols")
CopySource = File.join(CurrentDir, "bin")

$stripAfterInstall = true
$extractSymbols = true

# Try to guess Leviathan folder
if !$leviathanFolder

  if File.exists? File.join(CurrentDir, "../ThirdParty/Leviathan")
    $leviathanFolder = File.expand_path File.join(CurrentDir, "../ThirdParty/Leviathan")
  elsif File.exists? File.join(CurrentDir, "../Engine/Engine.h")
    $leviathanFolder = File.expand_path File.join(CurrentDir, "../Engine/Engine.h")
  else
    warning "Can't detect Leviathan folder automatically, packaging will likely fail"
  end

end

def extractor
  if OS.windows?
    File.join $leviathanFolder, "build/ThirdParty/bin", "dump_syms.exe"
  else
    File.join $leviathanFolder, "build/ThirdParty/bin", "dump_syms"
  end
end

# General Breakpad symbol dumper
def doSymbolDump(file)
  puts "Extracting symbols from: " + file
  FileUtils.mkdir_p SymbolTarget

  status, output = runOpen3CaptureOutput extractor, file

  if status != 0 || output == nil || output.length < 1
    puts "Extractor output: " + output[0..1000]
    onError "failed to extract symbols"
  end

  # Place it correctly (this makes local dumping work, but when
  # sending to a server this doesn't really matter
  platform, arch, hash, name = getBreakpadSymbolInfo output

  # puts "Symbol info: platform: #{platform}, arch: #{arch}, hash: #{hash}, name: #{name}"

  FileUtils.mkdir_p File.join(SymbolTarget, name, hash)

  File.write File.join(SymbolTarget, name, hash, name + ".sym"), output
end

# This handles non-stripped files on linux
def handleDebugInfoFileLinux(file)

  # Ignore symbolic links
  if File.symlink? file
    return
  end

  if $extractSymbols

    fileStatus = `file "#{file}"`

    if fileStatus.match /debug/i

      doSymbolDump file
    else
      puts "No symbols to extract in: " + file
    end
  end

  if !$stripAfterInstall
    return
  end

  puts "Stripping: " + file
  if runSystemSafe("strip", file) != 0
    onError "Failed to strip: " + file
  end
end

# This filters known "bad" and known good pdb files for windows
def filterPDBFile(file)
  case file
  when /vc\d\d+.pdb/i
    false
  when /breakpad\/src/i
    false
  when /OgreMeshTool.pdb/i
    false
  when /FileGenerator/i
    false
  when /Demos/i
    false
  when /Pong/i
    false
  # SFML debug info is in weird places
  when /sfml-.*\.pdb/i
    false
  else
    true
  end
end

# And this handles pdb files on windows
def handleDebugInfoFileWindows(file, delete: false)
  if !File.exist? file
    return
  end

  if $extractSymbols
    doSymbolDump file
  end

  if !$stripAfterInstall || !delete
    return
  end

  puts "Deleting debug file: " + file
  FileUtils.rm file
end

def removeIfExists(file)
  if File.exists? file
    puts "Removing temporary file: " + file
    FileUtils.rm_rf file, secure: true
  end
end

# This object holds the configuration needed for making a release
class ReleaseProperties

  attr_accessor :name, :executables, :extraFiles

  def initialize(name)
    @name = name
    @executables = []
    @extraFiles = []
  end

  def addExecutable(exe)
    @executables.push exe
  end

  def addFile(file)
    @extraFiles.push file
  end

end


def handlePlatform(props, platform, prettyName)

  fullName = props.name + prettyName

  target = File.join(CurrentDir, fullName)

  FileUtils.mkdir_p target

  binTarget = File.join(target, "bin")

  windowsSymbolSources = [File.join(CurrentDir, "bin"),
                          File.join($leviathanFolder, "build/bin"),
                          File.join($leviathanFolder, "build/ThirdParty"),
                          # And this is a ton of files to dig through
                          # And needs a lot of filters to work properly
                          File.join($leviathanFolder, "ThirdParty"),
                         ]

  # Install first with cmake
  Dir.chdir CurrentDir do

    info "Configuring install folder: #{target}"

    # Fail if not MAKE_RELEASE is not defined
    status, output = runOpen3CaptureOutput "cmake", "..", "-L", "-N"

    if status != 0 || !output.match(/MAKE_RELEASE:BOOL=1/i)

      if !$options[:allowDevelopment]
        onError "You need to compile the project with '-DMAKE_RELEASE=1' " +
                "before making a release. Or specify flags for development build"
      else
        warning "Making a development build. Crash reporting won't be enabled!"

        if $extractSymbols
          info "Disabling symbol extraction"
          $extractSymbols = false
        end
      end
    end

    if runSystemSafe("cmake", "..", "-DCMAKE_INSTALL_PREFIX=#{target}") != 0
      onError "Failed to configure cmake install folder"
    end

    case platform
    when "linux"

      if runSystemSafe("make", "install") != 0
        onError "Failed to run make install"
      end

    when "windows"

      if !runVSCompiler(1, project: "INSTALL.vcxproj", configuration: "RelWithDebInfo")
        onError "Failed to run msbuild install target"
      end

    else
      onError "unknown platform"
    end
  end

  if !File.exists? binTarget
    onError "Install failed to create bin folder"
  end

  File.write(File.join(target, "package_version.txt"), fullName)

  Dir.chdir(ProjectDir){

    File.open(File.join(target, "revision.txt"), 'w') {
      |file| file.write("Package time: " + Time.now.iso8601 + "\n\n" + `git log -n 1`)
    }
  }

  # Install custom files
  props.extraFiles.each{|i|
    copyPreserveSymlinks i, target
  }

  # This almost manages to run with a bundled libc
#   if platform == "linux"
#     launchFile = File.join(target, "launch.sh")

#     File.write(launchFile, <<-END
# #!/usr/bin/sh
# # This is a launch script for using the packaged libc version
# SCRIPT=$(readlink -f "$0")
# SCRIPT_PATH=$(dirname "$SCRIPT")
# (
#     cd "$SCRIPT_PATH/bin"
#     "$SCRIPT_PATH/bin/lib/ld-linux-x86-64.so.2" ./Thrive
# )
# END
#               )

#     FileUtils.chmod("+x", launchFile)
#     FileUtils.chmod("+x", File.join(binTarget, "lib/ld-linux-x86-64.so.2")
#   end

  info "Copying license files"
  # licenseFolder = File.join(target, "Licenses")
  # FileUtils.mkdir_p licenseFolder

  File.write File.join(target, "LeviathanLicense.txt"),
             File.read(File.join$leviathanFolder, "License.txt")

  # TODO: allow pausing here for manual testing
  info "Created folder: " + target
  puts "Now is an excellent time to verify that the folder is fine"
  puts "If it isn't press CTRL+C to cancel"
  waitForKeyPress


  # Then clean all logs and settings
  info "Cleaning logs and configuration files"
  removeIfExists File.join(binTarget, "Data/Cache")

  Dir.glob([File.join(binTarget, "*.conf"), File.join(binTarget, "*Persist.txt"),
            # These are Ogre cache files
            File.join(binTarget, "*.glsl"),
            # Log files
            File.join(binTarget, "*Log.txt"), File.join(binTarget, "*cAudioLog.html"),
            File.join(binTarget, "*LogOGRE.txt"), File.join(binTarget, "*LogCEF.txt")]
          ){|i|
    removeIfExists i
  }

  # And strip debug info
  if $stripAfterInstall or $extractSymbols
    info "Removing debug info"

    case platform
    when "linux"
      Dir.glob([File.join(binTarget, "**/*.so*")]){|i|
        handleDebugInfoFileLinux i
      }

      if File.exists? File.join(binTarget, "chrome-sandbox")
        handleDebugInfoFileLinux File.join(binTarget, "chrome-sandbox")
      end

      props.executables.each{|i| handleDebugInfoFileLinux File.join(binTarget, i)}

    when "windows"
      Dir.glob([File.join(binTarget, "**/*.pdb")]){|i|
        handleDebugInfoFileWindows i, delete: true
      }

      props.executables.each{|i| handleDebugInfoFileWindows(
                               File.join(binTarget, i.sub(/.exe$/i, "") + ".pdb"),
                               delete: true)}

      # TODO: find dependencies, they don't install pdb files, and the
      # project files as those also don't install pdb files

      # TODO: these should be done only once
      Dir.glob([File.join(binTarget, "**/*.pdb")]){|i|
        handleDebugInfoFileWindows i
      }

      windowsSymbolSources.each{|i|
        Dir.glob([File.join(i, "**/*.pdb")]){|i|

          if filterPDBFile i
            handleDebugInfoFileWindows i
          else
            puts "filtered out: " + i
          end
        }
      }
    else
      onError "unknown platform"
    end

  end

  if platform == "linux"
    info "Using ldd to find required system libraries and bundling them"

    # Use ldd to find more dependencies
    lddfound = props.executables.collect{|i| lddFindLibraries File.join(binTarget, i)}.flatten

    info "Copying #{lddfound.count} libraries found by ldd on project executables"

    copyDependencyLibraries(lddfound, File.join(binTarget, "lib/"), false, true)

    # Find dependencies of dynamic Ogre libraries
    lddfound = lddFindLibraries File.join(binTarget, "lib/Plugin_ParticleFX.so")

    info "Copying #{lddfound.count} libraries found by ldd on Ogre plugins"

    copyDependencyLibraries(lddfound, File.join(binTarget, "lib/"), false, true)

    success "Copied ldd found libraries"

    info "Copied #{HandledLibraries.count} libraries to lib directory"

  end

  # Zip it up
  if runSystemSafe(p7zip, "a", target + ".7z", target) != 0
    onError "Failed to zip folder: " + target
  end

  puts ""
  success "Created archive: #{target}.7z"
  info "SHA3: " + SHA3::Digest::SHA256.file(target + ".7z").hexdigest
  puts ""
end


# Main run method
def runMakeRelease(props)
  info "Starting release packager. Target: #{props.name}"

  if !File.exists? CopySource
    onError "#{CopySource} folder is missing. Did you compile the project?"
  end

  if OS.linux?

    # Generic Linux
    handlePlatform props, "linux", "-LINUX-generic"

    # TODO: OS specific Linux package
  elsif OS.windows?

    # Windows 64 bit
    handlePlatform props, "windows", "-WINDOWS-64bit"

  else
    onError "unknown platform to package for"
  end

  success "Done creating packages."
end
