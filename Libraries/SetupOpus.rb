# Supported extra options:
# 
class Opus < StandardCMakeDep
  def initialize(args)
    super("Opus", "opus", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/xiph/opus.git"
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
        "lib/opus.lib",
        "include/opus",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
