# Supported extra options:
# physicsModule: specify the physics module
# audioModule: specify the audio module
# renderAPI: specify the primary render API
# buildAllRenderAPI: if true build all render modules at once
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

    if args.include? :buildAllRenderAPI
      @Options.push "-DBUILD_ALL_RENDER_API=#{args[:buildAllRenderAPI]}"
    end

    if args.include? :extraLibSearch
      @Options.push "-DDYNLIB_EXTRA_SEARCH_DIRECTORY=#{args[:extraLibSearch]}"
    end

    @Options.push "-DBSF_ENABLE_EXCEPTIONS=ON"
    @Options.push "-DBSF_ENABLE_RTTI=ON"
    @Options.push "-DBSF_STRIP_DEBUG_INFO=OFF"

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/GameFoundry/bsf.git"
    end
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"

      return [
        "vulkan-headers", "vulkan-loader", "vulkan-tools", "vulkan-validation-layers"
      ]

    end

    if os == "ubuntu"

      return [
        "libvulkan-dev", "vulkan-tools", "vulkan-validationlayers"
      ]
    end

    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList

  end

  def translateBuildType(type)
    if type == "Debug"
      "Debug"
    else
      "Release"
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
