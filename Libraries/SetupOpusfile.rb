# Supported extra options:
# 
class Opusfile < StandardCMakeDep
  def initialize(args)
    super("Opusfile", "opusfile", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/xiph/opusfile.git"
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
        "lib/libopusfile.lib",
        "include/opusfile",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
