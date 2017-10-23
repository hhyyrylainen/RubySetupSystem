# Supported extra options:
#
class SFML < BaseDep
  def initialize(args)
    super("SFML", "SFML", args)

    self.HandleStandardCMakeOptions
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      return [
        "xcb-util-image-devel", "systemd-devel", "libjpeg-devel", "libvorbis-devel",
        "flac-devel", "openal-soft-devel"
      ]
    end

    if os == "ubuntu"
      return [
        "libxcb-image0-dev", "libsystemd-dev", " libjpeg9-dev", "libvorbis-dev",
        "libflac-devel", "libopenal-dev"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end

  def DoClone
    runOpen3("git", "clone", "https://github.com/SFML/SFML.git") == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end  

  def DoSetup
    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      return runCMakeConfigure @Options
    end
  end
  
  def DoCompile

    Dir.chdir("build") do
            
      return runCompiler $compileThreads
      
    end
  end
  
  def DoInstall
    Dir.chdir("build") do
      return self.cmakeUniversalInstallHelper
    end
  end
end
