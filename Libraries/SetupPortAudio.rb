# Supported extra options:
# :noOSS => Disable OSS support on linux (which is not supported well
#     according to the documentation
class PortAudio < BaseDep
  def initialize(args)

    super("PortAudio", "portaudio", args)

    if @InstallPath
      if usesCMake
        @Options.push "-DCMAKE_INSTALL_PREFIX=#{@InstallPath}"
      else
        @Options.push "--prefix='#{@InstallPath}'"
      end  
    end

    if args[:noOSS]
      if usesCMake
      # Doesn't make sense on windows, and the cmake doesn't seem
      # to have 'OSS' in it so probably doesn't need to be disabled
      # even if we switch linux to also use cmake
      else
        @Options.push "--without-oss"
      end
    end
    
  end
  
  # Returns true if platform uses cmake to configure, and cmake style args
  # should be used
  def usesCMake
    OS.windows?
  end

  
  def getDefaultOptions
    if !usesCMake
      []
    else
      [
        "-DPA_DLL_LINK_WITH_STATIC_RUNTIME=OFF",
      ]
    end

  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      
      return [
        "alsa-lib-devel"
      ]
      
    end

    if os == "ubuntu"
      
      return [
        "libasound-dev"
      ]
    end
    
    onError "#{@Name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end

  def DoClone
    runSystemSafe("git", "clone", "https://git.assembla.com/portaudio.git", "portaudio") == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  def DoSetup

    if OS.windows?
      
      FileUtils.mkdir_p "build"
      
      Dir.chdir("build") do
        
        return runCMakeConfigure @Options
      end
    else

      runSystemSafe("./configure", @Options.join) == 0
    end
  end
  
  def DoCompile
    if OS.windows?
      
      Dir.chdir("build") do
        
        # If we ran cmake again here with 32 bit windows (probably in a 'build-32' folder)
        # we could probably also build the 32-bit version as it has a different file name 
        return runVSCompiler $compileThreads, "portaudio.vcxproj", "Release", "x64"
      end
    else

      return runCompiler $compileThreads
    end
  end

  def DoInstall

    if OS.windows?
      
      buildFolder = File.join(@Folder, "build/Release/")
      
      if Dir.glob(File.join(buildFolder, "*.dll")).empty? 
        onError "portaudio files to be installed are missing"
      end
      
      binFolder = File.join @InstallPath, "bin"
      libFolder = File.join @InstallPath, "lib"

      FileUtils.mkdir_p binFolder
      FileUtils.mkdir_p libFolder
      
      Dir.glob(File.join(buildFolder, "*.dll")) {|file|
        FileUtils.cp file, binFolder
      }
      
      Dir.glob(File.join(buildFolder, "*.lib")) {|file|
        FileUtils.cp file, libFolder
      }
      
      FileUtils.cp_r File.join(@Folder, "include"), @InstallPath
      
      true
      
    else
      
      return self.linuxMakeInstallHelper
    end
  end
end
