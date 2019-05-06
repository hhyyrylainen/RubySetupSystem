# Supported extra options:
# physicsModule: specify the physics module
# audioModule: specify the audio module
# renderAPI: specify the primary render API
class BSFramework < StandardCMakeDep
  def initialize(args)
    super("bs::framework", "bsf", args)

    if args.include? :physicsModule
      @Options.push "-DPHYSICS_MODULE=#{args[:physicsModule]}"
    end

    if args.include? :audioModule
      @Options.push "-DAUDIO_MODULE=#{args[:audioModule]}"
    end

    if args.include? :renderAPI
      @Options.push "-DRENDER_API_MODULE=#{args[:renderAPI]}"
    end

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/GameFoundry/bsf.git"
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
      onError "TODO: windows precompiled files"
      [
        # data files
        "bin/Data",

        # includes
        "include/bsfUtility",
        "include/bsfCore",
        "include/bsfEngine",

        # libraries

        # executables
        "bin/bsfImportTool.exe",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end


