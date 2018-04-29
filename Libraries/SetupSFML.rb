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
        "libxcb-image0-dev", "libsystemd-dev", "libjpeg9-dev", "libvorbis-dev",
        "libflac-dev", "libopenal-dev"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end

  def DoClone
    runSystemSafe("git", "clone", @RepoURL) == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  def getInstalledFiles
    if OS.windows?
      [
        "lib/sfml-audio.lib",
        "lib/sfml-graphics.lib",
        "lib/sfml-network.lib",
        "lib/sfml-system.lib",
        "lib/sfml-window.lib",
        "lib/openal32.lib",

        "bin/sfml-audio-2.dll",
        "bin/sfml-graphics-2.dll",
        "bin/sfml-network-2.dll",
        "bin/sfml-system-2.dll",
        "bin/sfml-window-2.dll",
        "bin/openal32.dll",

        "include/SFML",
        # This seems to be sfml license
        "license.txt",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
