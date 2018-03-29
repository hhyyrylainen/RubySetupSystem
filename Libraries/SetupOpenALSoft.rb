# Supported extra options:
#
class OpenALSoft < StandardCMakeDep
  def initialize(args)
    super("OpenAL Soft", "openal-soft", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/kcat/openal-soft.git"
    end
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      return [
        "alsa-lib-devel", "pulseaudio-libs-devel"
      ]
    end

    if os == "ubuntu"
      return [
        "libasound2-dev", "lib-pulse-dev"
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
      onError "TODO: openal-soft file list"
      [
        "lib/OpenAL32.lib",
        "bin/OpenAL32.dll",
        "include/AL",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
