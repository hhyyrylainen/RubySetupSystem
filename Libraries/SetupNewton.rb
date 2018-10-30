# Supported extra options:
# :disableDemos => disable demo programs
# Requires tinyxml
class Newton < StandardCMakeDep
  def initialize(args)
    super("Newton Dynamics", "newton-dynamics", args)

    if args[:disableDemos]
      @Options.push "-DNEWTON_BUILD_SANDBOX_DEMOS=OFF"
    end

    if args[:disableProfiler]
      @Options.push "-DNEWTON_BUILD_PROFILER=OFF"
    end

    if args[:shared]
      @Options.push "-DNEWTON_BUILD_SHARED_LIBS=ON"
    else
      @Options.push "-DNEWTON_BUILD_SHARED_LIBS=OFF"
    end

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/MADEAPPS/newton-dynamics.git"
    end
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      return [
        "tinyxml-devel"
      ]
    end

    if os == "ubuntu"
      return [
        "libtinyxml-dev"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites
    
    installDepsList depsList
    
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
        "lib/Newton.dll",
        "lib/Newton.lib",
        "include/Newton.h",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
