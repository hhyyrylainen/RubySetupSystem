# Supported extra options:
# 
class Ogg < StandardCMakeDep
  def initialize(args)
    super("Ogg", "ogg", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/xiph/ogg.git"
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
        "lib/ogg.lib",
        "include/ogg",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
