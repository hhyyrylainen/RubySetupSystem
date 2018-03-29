# Supported extra options:
#
class CAudio < StandardCMakeDep
  def initialize(args)
    super("cAudio", "cAudio", args)

    self.HandleStandardCMakeOptions

    if args[:noTutorials]

      @Options.push "-DCAUDIO_BUILD_SAMPLES=OFF"
    end

    if !@RepoURL
      @RepoURL = "https://github.com/hhyyrylainen/cAudio.git"
    end
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      return [
        "openal-soft-devel"
      ]
    end

    if os == "ubuntu"
      return [
        "openal-soft-dev"
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

  def getInstalledFiles
    if OS.windows?
      onError "TODO: the cAudio file list"
      [
        "lib/cAudio.lib",
        "bin/cAudio.dll",
        "include/cAudio",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
