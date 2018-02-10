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
end
