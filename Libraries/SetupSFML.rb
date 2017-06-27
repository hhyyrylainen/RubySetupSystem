# Supported extra options:
#
class SFML < BaseDep
  def initialize(args)
    super("SFML", "SFML", args)

    if @InstallPath
      @Options.push "-DCMAKE_INSTALL_PREFIX=\"#{@InstallPath}\""
    end
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      
      return [
        "xcb-util-image-devel", "systemd-devel", "libjpeg-devel", "libvorbis-devel",
        "flac-devel"
      ]
      
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end

  def DoClone
    requireCMD "git"
    system "git clone https://github.com/SFML/SFML.git"
    $?.exitstatus == 0
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
            
      return runCompiler CompileThreads
      
    end
  end
  
  def DoInstall
    Dir.chdir("build") do
      return self.cmakeUniversalInstallHelper
    end
  end
end
