# Supported extra options:
#
# Note: the current leviathan versions aren't meant to be installed so
# the install path is mostly ignored
class Leviathan < BaseDep
  def initialize(args)
    super("Leviathan", "Leviathan", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/hhyyrylainen/Leviathan.git"
    end
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      return [
        "cscope", "boost-devel", "SDL2-devel", "ImageMagick"
      ]
    end

    if os == "ubuntu"
      return [
        "cscope", "libboost-dev", "libsdl2-dev", "imagemagick"
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
    if !self.standardGitUpdate 
      return false
    end
    runOpen3Checked("git", "submodule", "init")
    runSystemSafe("git", "submodule", "update") == 0
  end  

  def DoSetup
    # TODO: find a way to run the leviathan dependencies here
    true
  end
  
  def DoCompile
    # This step takes care of everything setup and compiling
    runSystemSafe(*["ruby", "Setup.rb", passOptionsToSubRubySetupSystemProject].flatten) == 0
  end
  
  def DoInstall
    # Installation not used
    
    # Dir.chdir("build") do
    #   return self.cmakeUniversalInstallHelper
    # end
    true
  end
end
