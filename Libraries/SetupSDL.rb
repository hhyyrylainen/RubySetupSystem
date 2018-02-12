# Supported extra options:
#
class SDL < StandardCMakeDep
  def initialize(args)
    super("SDL2", "SDL", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "http://hg.libsdl.org/SDL"
    end
  end

  def DoClone
    runOpen3("hg", "clone", @RepoURL) == 0
  end

  def DoUpdate
    runOpen3("hg", "pull")
    runOpen3("hg", "update", @Version) == 0
  end

  def getInstalledFiles
    if OS.windows?
      [
        "bin/SDL2.dll",
        
        "lib/SDL2.lib",
        "lib/SDL2main.lib",
        "lib/SDL2-static.lib",

        "include/SDL2",
      ]
    else
      onError "TODO: linux file list"
    end
  end
end
