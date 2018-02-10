# Supported extra options:
#
class SFML < StandardCMakeDep
  def initialize(args)
    super("SFML", "SFML", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/SFML/SFML.git"
    end
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
    runOpen3("git", "clone", @RepoURL) == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end  
end
