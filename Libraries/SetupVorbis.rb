# Supported extra options:
# 
class Vorbis < StandardCMakeDep
  def initialize(args)
    super("Vorbis", "vorbis", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/xiph/vorbis.git"
    end
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
        "lib/vorbis.lib",
        "lib/vorbisenc.lib",
        "lib/vorbisfile.lib",
        "include/vorbis",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
