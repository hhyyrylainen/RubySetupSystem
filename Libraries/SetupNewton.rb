# Supported extra options:
# :disableDemos => disable demo programs
# Requires tinyxml
class Newton < StandardCMakeDep
  def initialize(args)
    super("Newton Dynamics", "newton-dynamics", args)

    # No longer exists
    if args[:disableDemos]
      @Options.push "-DNEWTON_DEMOS_SANDBOX=OFF"
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
    runOpen3("git", "clone", @RepoURL) == 0
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
      onError "TODO: linux file list"
    end
  end
end
