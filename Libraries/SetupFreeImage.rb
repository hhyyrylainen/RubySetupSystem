# Supported extra options:
#
class FreeImage < StandardCMakeDep
  def initialize(args)
    super("FreeImage", "FreeImage", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/hhyyrylainen/FreeImage.git"
    end

    @BranchEpoch = 2
  end

  def DoClone
    runOpen3("git", "clone", @RepoURL) == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end
  
  def getInstalledFiles
    if OS.windows?
      [
        "lib/FreeImage.lib",
        "lib/FreeImage.dll",

        "include/FreeImage.h",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
