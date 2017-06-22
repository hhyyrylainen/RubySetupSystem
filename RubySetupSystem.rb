# coding: utf-8
# A ruby script for downloading and installing C++ project dependencies
# Made by Henri Hyyryläinen

require_relative 'RubyCommon.rb'
require_relative 'DepGlobber.rb'

require 'optparse'
require 'fileutils'
require 'etc'
require 'os'
require 'open3'
require 'pathname'
require 'zip'

## Used by: verifyVSProjectRuntimeLibrary
#require 'nokogiri' if OS.windows?
## Required for installs on windows
##require 'win32ole' if OS.windows?


#
# Parse options
#

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: Setup.rb [OPTIONS]"

  opts.on("--[no-]sudo", "Run commands that need sudo. " +
                         "This may be needed to run successfuly") do |b|
    options[:sudo] = b
  end 
  opts.on("--only-project", "Skip all dependencies setup") do |b|
    options[:onlyProject] = true
  end

  opts.on("--only-deps", "Skip the main project setup") do |b|
    options[:onlyDeps] = true
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    if defined? extraHelp
      puts extraHelp
    end
    exit
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
CompileThreads = Etc.nprocessors

# If set to true will install CEGUI editor
# Note: this doesn't work
InstallCEED = false

# If set to false won't install libs that need sudo
DoSudoInstalls = if options.include?(:sudo) then options[:sudo] else true end

# If true dependencies won't be updated from remote repositories
SkipPullUpdates = false

# If true skips all dependencies
OnlyMainProject = if options[:onlyProject] then true else false end

# If true skips the main project
OnlyDependencies = if options[:onlyDeps] then true else false end

# If true new version of depot tools and breakpad won't be fetched on install
NoBreakpadUpdateOnWindows = false

# On windows visual studio will be automatically opened if required
AutoOpenVS = true

# Visual studio version on windows, required for forced 64 bit builds
VSVersion = "Visual Studio 14 2015 Win64"
VSToolsEnv = "VS140COMNTOOLS"

# TODO create a variable for running the package manager on linux if possible

### Commandline handling
# TODO: add this

if OS.linux?
  HasDNF = which("dnf") != nil
else
  HasDNF = false
end

# This verifies that CurrentDir is good and assigns it to CurrentDir
CurrentDir = checkRunFolder Dir.pwd

ProjectDir = projectFolder CurrentDir

ProjectDebDir = File.join ProjectDir, "libraries"

ProjectDebDirLibs = File.join ProjectDebDir, "lib"

ProjectDebDirBinaries = File.join ProjectDebDir, "bin"

ProjectDebDirInclude = File.join ProjectDebDir, "include"

#
# Initial options / status print
#

info "Running in dir '#{CurrentDir}'"
puts "Project dir is '#{ProjectDir}'"

if HasDNF
  info "Using dnf package manager"
end

puts "Using #{CompileThreads} threads to compile, configuration: #{CMakeBuildType}"

require_relative "Installer.rb"
require_relative "RubyCommon.rb"
require_relative "WindowsHelpers.rb"

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

### Standard stuff


require_relative "LibraryCopy.rb"


require_relative "Dependency.rb"


#### Library Install Definitions ###
# Library installs are now in separate files in the Libraries sub directory


  
#
##
### TODO: all the following need to be fixed / verified that they still work
##
#

class Newton < BaseDep
  def initialize
    super("Newton Dynamics", "newton-dynamics")
  end

  def DoClone
    requireCMD "git"
    system "git clone https://github.com/MADEAPPS/newton-dynamics.git"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "git checkout master"
    system "git pull origin master"
    $?.exitstatus == 0
  end

  def DoSetup
    
    if OS.windows?
      
      return File.exist? "packages/projects/visualStudio_2015_dll/build.sln"
    else
      FileUtils.mkdir_p "build"

      Dir.chdir("build") do
        
        runCMakeConfigure "-DNEWTON_DEMOS_SANDBOX=OFF"
        return $?.exitstatus == 0
      end
    end      
  end
  
  def DoCompile
    if OS.windows?
      cmdStr = "#{bringVSToPath} && MSBuild.exe \"packages/projects/visualStudio_2015_dll/build.sln\" " +
               "/maxcpucount:#{CompileThreads} /p:Configuration=release /p:Platform=\"x64\""
      system cmdStr
      return $?.exitstatus == 0
    else
      Dir.chdir("build") do
        
        runCompiler CompileThreads
        
      end
      return $?.exitstatus == 0
    end
  end
  
  def DoInstall
    
    # Copy files to ProjectDir dependencies folder
    createDependencyTargetFolder

    runGlobberAndCopy(Globber.new("Newton.h", File.join(@Folder, "coreLibrary_300/source")),
                          ProjectDebDirInclude)
    
    if OS.linux?

      runGlobberAndCopy(Globber.new("libNewton.so", File.join(@Folder, "build/lib")),
                            ProjectDebDirLibs)

    elsif OS.windows?

      runGlobberAndCopy(Globber.new("newton.dll",
                                    File.join(@Folder, "coreLibrary_300/projects/windows")),
                            ProjectDebDirBinaries)

      runGlobberAndCopy(Globber.new("newton.lib",
                                    File.join(@Folder, "coreLibrary_300/projects/windows")),
                            ProjectDebDirLibs)
    else
      onError "Unkown os"
    end
    true
  end
end

class OpenAL < BaseDep
  def initialize
    super("OpenAL Soft", "openal-soft")
    onError "Use OpenAL from package manager on linux" if !OS.windows?
  end

  def DoClone
    requireCMD "git"
    system "git clone https://github.com/kcat/openal-soft.git"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "git checkout master"
    system "git pull origin master"
    $?.exitstatus == 0
  end

  def DoSetup
    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      
      runCMakeConfigure "-DALSOFT_UTILS=OFF -DALSOFT_EXAMPLES=OFF -DALSOFT_TESTS=OFF"
    end
    
    $?.exitstatus == 0
  end
  
  def DoCompile

    Dir.chdir("build") do
      runCompiler CompileThreads
    end
    $?.exitstatus == 0
  end
  
  def DoInstall
    return false if not DoSudoInstalls
    
    Dir.chdir("build") do
      runInstall
      
      if OS.windows? and not File.exist? "C:/Program Files/OpenAL/include/OpenAL"
        # cAudio needs OpenAL folder in include folder, which doesn't exist. 
        # So we create it here
        askToRunAdmin("mklink /D \"C:/Program Files/OpenAL/include/OpenAL\" " + 
                      "\"C:/Program Files/OpenAL/include/AL\"")
      end
    end
    $?.exitstatus == 0
  end
end

class CAudio < BaseDep
  def initialize
    super("cAudio", "cAudio")
  end

  def DoClone
    requireCMD "git"
    #system "git clone https://github.com/R4stl1n/cAudio.git"
    # Official repo is broken
    system "git clone https://github.com/hhyyrylainen/cAudio.git"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "git checkout master"
    system "git pull origin master"
    $?.exitstatus == 0
  end

  def DoSetup
    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      
      if OS.windows?
        # The bundled ones aren't compatible with our compiler setup 
        # -DCAUDIO_DEPENDENCIES_DIR=../Dependencies64
        runCMakeConfigure "-DCAUDIO_BUILD_SAMPLES=OFF -DCAUDIO_DEPENDENCIES_DIR=\"C:/Program Files/OpenAL\" " +
                          "-DCMAKE_INSTALL_PREFIX=./Install"
      else
        runCMakeConfigure "-DCAUDIO_BUILD_SAMPLES=OFF"
      end
    end
    
    $?.exitstatus == 0
  end
  
  def DoCompile

    Dir.chdir("build") do
      runCompiler CompileThreads
    end
    $?.exitstatus == 0
  end
  
  def DoInstall
    
    Dir.chdir("build") do
      if OS.windows?
        
        system "#{bringVSToPath} && MSBuild.exe INSTALL.vcxproj /p:Configuration=RelWithDebInfo"
        
        # And then to copy the libs
        
        FileUtils.mkdir_p File.join(CurrentDir, "cAudio")
        FileUtils.mkdir_p File.join(CurrentDir, "cAudio", "lib")
        FileUtils.mkdir_p File.join(CurrentDir, "cAudio", "bin")
        
        FileUtils.cp File.join(@Folder, "build/bin/RelWithDebInfo", "cAudio.dll"),
                     File.join(CurrentDir, "cAudio", "bin")

        FileUtils.cp File.join(@Folder, "build/lib/RelWithDebInfo", "cAudio.lib"),
                     File.join(CurrentDir, "cAudio", "lib")
        
        FileUtils.copy_entry File.join(@Folder, "build/Install/", "include"),
                             File.join(CurrentDir, "cAudio", "include")
        
      else
        return true if not DoSudoInstalls
        runInstall
      end
    end
    $?.exitstatus == 0
  end
end

class AngelScript < BaseDep
  def initialize
    super("AngelScript", "angelscript")
    @WantedURL = "http://svn.code.sf.net/p/angelscript/code/tags/2.31.2"

    if @WantedURL[-1, 1] == '/'
      onError "Invalid configuraion in Setup.rb AngelScript tag has an ending '/'. Remove it!"
    end
  end

  def DoClone
    requireCMD "svn"
    system "svn co #{@WantedURL} angelscript"
    $?.exitstatus == 0
  end

  def DoUpdate

    # Check is tag correct
    match = `svn info`.strip.match(/.*URL:\s?(.*angelscript\S+).*/i)

    onError("'svn info' unable to find URL with regex") if !match
    
    currenturl = match.captures[0]

    if currenturl != @WantedURL
      
      info "Switching AngelScript tag from #{currenturl} to #{@WantedURL}"
      
      system "svn switch #{@WantedURL}"
      onError "Failed to switch svn url" if $?.exitstatus > 0
    end
    
    system "svn update"
    $?.exitstatus == 0
  end

  def DoSetup
    if OS.windows?
      
      return File.exist? "sdk/angelscript/projects/msvc2015/angelscript.sln"
    else
      return true
    end
  end
  
  def DoCompile

    if OS.windows?
      info "Verifying that angelscript solution has Runtime Library = MultiThreadedDLL"
      verifyVSProjectRuntimeLibrary "sdk/angelscript/projects/msvc2015/angelscript.vcxproj", 
                                    %r{Release\|x64}, "MultiThreadedDLL"  
      
      success "AngelScript solution is correctly configured. Compiling"
      
      cmdStr = "#{bringVSToPath} && MSBuild.exe \"sdk/angelscript/projects/msvc2015/angelscript.sln\" " +
               "/maxcpucount:#{CompileThreads} /p:Configuration=Release /p:Platform=\"x64\""
      system cmdStr
      $?.exitstatus == 0
      
    else
    
      Dir.chdir("sdk/angelscript/projects/gnuc") do
        
        system "make -j #{CompileThreads}"
        return $?.exitstatus == 0
      end
    end
  end
  
  def DoInstall

    # Copy files to Project folder
    createDependencyTargetFolder

    # First header files and addons
    FileUtils.cp File.join(@Folder, "sdk/angelscript/include", "angelscript.h"),
                 ProjectDebDirInclude

    addondir = File.join(ProjectDebDirInclude, "add_on")

    FileUtils.mkdir_p addondir

    # All the addons from
    # `ls -m | awk 'BEGIN { RS = ","; ORS = ", "}; NF { print "\""$1"\""};'`
    addonnames = Array[
      "autowrapper", "contextmgr", "datetime", "debugger", "scriptany", "scriptarray",
      "scriptbuilder", "scriptdictionary", "scriptfile", "scriptgrid", "scripthandle",
      "scripthelper", "scriptmath", "scriptstdstring", "serializer", "weakref"
    ]

    addonnames.each do |x|

      FileUtils.copy_entry File.join(@Folder, "sdk/add_on/", x),
                           File.join(addondir, x)
    end

    # Then the library
    if OS.linux?

      FileUtils.cp File.join(@Folder, "sdk/angelscript/lib", "libangelscript.a"),
                   ProjectDebDirLibs
      
    elsif OS.windows?
      FileUtils.cp File.join(@Folder, "sdk/angelscript/lib", "angelscript64.lib"),
                   ProjectDebDirLibs
    else
      onError "Unkown OS"
    end
    true
  end
end

class Breakpad < BaseDep
  def initialize
    super("Google Breakpad", "breakpad")
    @DepotFolder = File.join(CurrentDir, "depot_tools")
    @CreatedNewFolder = false
  end

  def RequiresClone
    if File.exist?(@DepotFolder) and File.exist?(@Folder)
      return false
    end
    
    true
  end
  
  def DoClone
    requireCMD "git"
    # Depot tools
    system "git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git"
    return false if $?.exitstatus > 0

    if not File.exist?(@Folder)
      
      FileUtils.mkdir_p @Folder
      @CreatedNewFolder = true
      
    end
    
    true
  end

  def DoUpdate
    
    if OS.windows? and NoBreakpadUpdateOnWindows
      info "Windows: skipping Breakpad update"
      if not File.exist?("src")
        @CreatedNewFolder = true
      end
      return true
    end

    # Update depot tools
    Dir.chdir(@DepotFolder) do
      system "git checkout master"
      system "git pull origin master"
    end

    if $?.exitstatus > 0
      return false
    end

    if not @CreatedNewFolder
      
      if not File.exist?("src")
        # This is set to true if we created an empty folder but we didn't get to the pull stage
        @CreatedNewFolder = true
      else
        Dir.chdir(@Folder) do
          # The first source subdir is the git repository
          Dir.chdir("src") do
            system "git checkout master"
            system "git pull origin master"
            system "gclient sync"
          end
        end
      end
    end
    
    true
  end

  def DoSetup
    
    if not @CreatedNewFolder
      return true
    end
    
    # Bring the depot tools to path
    pathedit = PathModifier.new(@DepotFolder)

    # Get source for breakpad
    Dir.chdir(@Folder) do

      system "fetch breakpad"

      if $?.exitstatus > 0
        pathedit.Restore
        onError "fetch breakpad failed"
      end
      
      Dir.chdir("src") do

        # Configure script
        if OS.windows?
          system "src/tools/gyp/gyp.bat src/client/windows/breakpad_client.gyp –no-circular-check"
        else
          system "./configure"
        end
        
        if $?.exitstatus > 0
          pathedit.Restore
          onError "configure breakpad failed" 
        end
      end
    end

    pathedit.Restore
    true
  end
  
  def DoCompile

    # Bring the depot tools to path
    pathedit = PathModifier.new(@DepotFolder)

    # Build breakpad
    Dir.chdir(File.join(@Folder, "src")) do
      
      if OS.windows?
        info "Please open the solution at and compile breakpad client in Release and x64. " +
             "Remember to disable treat warnings as errors first: "+
             "#{CurrentDir}/breakpad/src/src/client/windows/breakpad_client.sln"
        
        system "start #{CurrentDir}/breakpad/src/src/client/windows/breakpad_client.sln" if AutoOpenVS
        system "pause"
      else
        system "make -j #{CompileThreads}"
        
        if $?.exitstatus > 0
          pathedit.Restore
          onError "breakpad build failed" 
        end
      end
    end
    
    pathedit.Restore
    true
  end
  
  def DoInstall

    # Create target folders
    FileUtils.mkdir_p File.join(CurrentDir, "Breakpad", "lib")
    FileUtils.mkdir_p File.join(CurrentDir, "Breakpad", "bin")

    breakpadincludelink = File.join(CurrentDir, "Breakpad", "include")
    
    if OS.windows?

      askToRunAdmin "mklink /D \"#{breakpadincludelink}\" \"#{File.join(@Folder, "src/src")}\""
      
      FileUtils.copy_entry File.join(@Folder, "src/src/client/windows/Release/lib"),
                           File.join(CurrentDir, "Breakpad", "lib")
      
      
      
    # Might be worth it to have windows symbols dumbed on windows, if the linux dumber can't deal with pdbs
    #FileUtils.cp File.join(@Folder, "src/src/tools/linux/dump_syms", "dump_syms"),
    #             File.join(CurrentDir, "Breakpad", "bin")
      
    else
      
      # Need to delete old file before creating a new symlink
      File.delete(breakpadincludelink) if File.exist?(breakpadincludelink)
      FileUtils.ln_s File.join(@Folder, "src/src"), breakpadincludelink
      
      FileUtils.cp File.join(@Folder, "src/src/client/linux", "libbreakpad_client.a"),
                   File.join(CurrentDir, "Breakpad", "lib")

      FileUtils.cp File.join(@Folder, "src/src/tools/linux/dump_syms", "dump_syms"),
                   File.join(CurrentDir, "Breakpad", "bin")

      FileUtils.cp File.join(@Folder, "src/src/processor", "minidump_stackwalk"),
                   File.join(CurrentDir, "Breakpad", "bin")
    end
    true
  end
end

class Ogre < BaseDep
  def initialize
    super("Ogre", "ogre")
  end

  def RequiresClone
    if OS.windows?
      return (not File.exist?(@Folder) or not File.exist?(File.join(@Folder, "Dependencies")))
    else
      return (not File.exist? @Folder)
    end
  end
  
  def DoClone
    requireCMD "hg"
    if OS.windows?

      system "hg clone https://bitbucket.org/sinbad/ogre"
      if $?.exitstatus > 0
        return false
      end
      
      Dir.chdir(@Folder) do

        system "hg clone https://bitbucket.org/cabalistic/ogredeps Dependencies"
      end
      return $?.exitstatus == 0
    else
      system "hg clone https://bitbucket.org/sinbad/ogre"
      return $?.exitstatus == 0
    end
  end

  def DoUpdate
    
    if OS.windows?
      Dir.chdir("Dependencies") do
        system "hg pull"
        system "hg update"
        
        if $?.exitstatus > 0
          return false
        end
      end
    end
    
    system "hg pull"
    system "hg update v2-0"
    $?.exitstatus == 0
  end

  def DoSetup
    
    # Dependencies compile
    additionalCMake = ""
    
    if OS.windows?
      Dir.chdir("Dependencies") do
        
        system "cmake . -DOGREDEPS_BUILD_SDL2=OFF" 
        
        system "#{bringVSToPath} && MSBuild.exe ALL_BUILD.vcxproj /maxcpucount:#{CompileThreads} /p:Configuration=Debug"
        onError "Failed to compile Ogre dependencies " if $?.exitstatus > 0
        
        runCompiler CompileThreads
        onError "Failed to compile Ogre dependencies " if $?.exitstatus > 0

        info "Please open the solution SDL2 in Release and x64: "+
             "#{@Folder}/Dependencies/src/SDL2/VisualC/SDL_VS2013.sln"
        
        system "start #{@Folder}/Dependencies/src/SDL2/VisualC/SDL_VS2013.sln" if AutoOpenVS
        system "pause"
        
        additionalCMake = "-DSDL2MAIN_LIBRARY=..\SDL2\VisualC\Win32\Debug\SDL2main.lib " +
                          "-DSD2_INCLUDE_DIR=..\SDL2\include"
        "-DSDL2_LIBRARY_TEMP=..\SDL2\VisualC\Win32\Debug\SDL2.lib"
        
      end
    end
    
    FileUtils.mkdir_p "build"
    
    Dir.chdir("build") do

      runCMakeConfigure "-DOGRE_BUILD_RENDERSYSTEM_GL3PLUS=ON " +
                        "-DOGRE_BUILD_RENDERSYSTEM_D3D9=OFF -DOGRE_BUILD_RENDERSYSTEM_D3D11=OFF "+
                        "-DOGRE_BUILD_COMPONENT_OVERLAY=OFF " +
                        "-DOGRE_BUILD_COMPONENT_PAGING=OFF -DOGRE_BUILD_COMPONENT_PROPERTY=OFF " +
                        "-DOGRE_BUILD_COMPONENT_TERRAIN=OFF -DOGRE_BUILD_COMPONENT_VOLUME=OFF "+
                        "-DOGRE_BUILD_PLUGIN_BSP=OFF -DOGRE_BUILD_PLUGIN_CG=OFF " +
                        "-DOGRE_BUILD_PLUGIN_OCTREE=OFF -DOGRE_BUILD_PLUGIN_PCZ=OFF -DOGRE_BUILD_SAMPLES=OFF " + 
                        additionalCMake
    end
    
    $?.exitstatus == 0
  end
  
  def DoCompile
    Dir.chdir("build") do
      if OS.windows?
        system "#{bringVSToPath} && MSBuild.exe ALL_BUILD.vcxproj /maxcpucount:#{CompileThreads} /p:Configuration=Release"
        system "#{bringVSToPath} && MSBuild.exe ALL_BUILD.vcxproj /maxcpucount:#{CompileThreads} /p:Configuration=RelWithDebInfo"
      else
        runCompiler CompileThreads
      end
    end
    
    $?.exitstatus == 0
  end
  
  def DoInstall

    Dir.chdir("build") do
      
      if OS.windows?

        system "#{bringVSToPath} && MSBuild.exe INSTALL.vcxproj /p:Configuration=RelWithDebInfo"
        ENV["OGRE_HOME"] = "#{@Folder}/build/ogre/sdk"
        
      else
        return true if not DoSudoInstalls
        runInstall
      end
    end

    $?.exitstatus == 0
  end
end

# Windows only CEGUI dependencies
class CEGUIDependencies < BaseDep
  def initialize
    super("CEGUI Dependencies", "cegui-dependencies")
  end

  def DoClone
    requireCMD "hg"
    system "hg clone https://bitbucket.org/cegui/cegui-dependencies"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "hg pull"
    system "hg update default"
    $?.exitstatus == 0
  end

  def DoSetup

    FileUtils.mkdir_p "build"

    if InstallCEED
      python = "ON"
    else
      python = "OFF"
    end

    Dir.chdir("build") do
      runCMakeConfigure "-DCEGUI_BUILD_PYTHON_MODULES=#{python} "
    end
    
    $?.exitstatus == 0
  end
  
  def DoCompile

    Dir.chdir("build") do
      system "#{bringVSToPath} && MSBuild.exe ALL_BUILD.vcxproj /maxcpucount:#{CompileThreads} /p:Configuration=Debug"
      system "#{bringVSToPath} && MSBuild.exe ALL_BUILD.vcxproj /maxcpucount:#{CompileThreads} /p:Configuration=RelWithDebInfo"
    end
    $?.exitstatus == 0
  end
  
  def DoInstall

    FileUtils.copy_entry File.join(@Folder, "build", "dependencies"),
                         File.join(CurrentDir, "cegui", "dependencies")
    $?.exitstatus == 0
  end
end

# Depends on Ogre to be installed
# TODO: put the deps in here and use package manager on linux
class CEGUI < BaseDep
  def initialize
    super("CEGUI", "cegui")
  end

  def DoClone
    requireCMD "hg"
    system "hg clone https://bitbucket.org/cegui/cegui"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "hg pull"
    #system "hg update default"

    # TODO: allow configuring this commit
    system "hg update 6510156"
    
    $?.exitstatus == 0
  end

  def DoSetup

    FileUtils.mkdir_p "build"

    if InstallCEED
      python = "ON"
    else
      python = "OFF"
    end

    Dir.chdir("build") do
      # Use UTF-8 strings with CEGUI (string class 1)
      runCMakeConfigure "-DCEGUI_STRING_CLASS=1 " +
                        "-DCEGUI_BUILD_APPLICATION_TEMPLATES=OFF -DCEGUI_BUILD_PYTHON_MODULES=#{python} " +
                        "-DCEGUI_SAMPLES_ENABLED=OFF -DCEGUI_BUILD_RENDERER_DIRECT3D11=OFF -DCEGUI_BUILD_RENDERER_OGRE=ON " +
                        "-DCEGUI_BUILD_RENDERER_OPENGL=OFF -DCEGUI_BUILD_RENDERER_OPENGL3=OFF"
    end
    
    $?.exitstatus == 0
  end
  
  def DoCompile

    Dir.chdir("build") do
      runCompiler CompileThreads 
    end
    $?.exitstatus == 0
  end
  
  def DoInstall

    return true if not DoSudoInstalls or BuildPlatform == "windows"
    
    Dir.chdir("build") do
      runInstall
    end
    $?.exitstatus == 0
  end
end

class SFML < BaseDep
  def initialize
    super("SFML", "SFML")
  end

  def DoClone
    requireCMD "git"
    system "git clone https://github.com/SFML/SFML.git"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "git checkout master"
    system "git pull origin master"
    $?.exitstatus == 0
  end

  def DoSetup
    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      runCMakeConfigure ""
    end
    
    $?.exitstatus == 0
  end
  
  def DoCompile

    Dir.chdir("build") do
      
      if BuildPlatform == "windows"
        system "#{bringVSToPath} && MSBuild.exe ALL_BUILD.vcxproj /maxcpucount:#{CompileThreads} /p:Configuration=Debug"
      end
      
      runCompiler CompileThreads
    end
    $?.exitstatus == 0
  end
  
  def DoInstall

    return true if not DoSudoInstalls or BuildPlatform == "windows"
    
    Dir.chdir("build") do
      runInstall
    end
    $?.exitstatus == 0
  end

  def LinuxPackages
    if getLinuxOS == "Fedora"
      return Array["xcb-util-image-devel", "systemd-devel", "libjpeg-devel", "libvorbis-devel",
                   "flac-devel"]
    else
      onError "LinuxPackages not done for this linux system"
    end
  end
end




