# Supported extra options:
#
# Note: the current leviathan versions aren't meant to be installed so
# the install path is mostly ignored
class Leviathan < BaseDep
  def initialize(args)
    super("Leviathan", "leviathan", args)

    if @InstallPath
      @Options.push "-DCMAKE_INSTALL_PREFIX=#{@InstallPath}"
    end
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      return [
        "cscope"
      ]
    end

    if os == "ubuntu"
      return [
        "cscope"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"
  end

  def installPrerequisites

    installDepsList depsList
  end  

  def DoClone
    runOpen3("git", "clone", "https://hhyyrylainen@bitbucket.org/hhyyrylainen/leviathan.git",
            "leviathan") == 0
  end

  def DoUpdate
    if !self.standardGitUpdate 
      return false
    end
    runOpen3Checked("git", "submodule", "init")
    runOpen3("git", "submodule", "update")
  end  

  def DoSetup
    # TODO: find a way to run the leviathan dependencies here
    # FileUtils.mkdir_p "build"

    # Dir.chdir("build") do
    #   return runCMakeConfigure @Options
    # end
    true
  end
  
  def DoCompile
    # This step takes care of everything

    # TODO: pass script options like no sudo etc. to child projects using RubySetupSystem
    runOpen3("ruby", "Setup.rb") == 0
  end
  
  def DoInstall
    # Installation not used
    
    # Dir.chdir("build") do
    #   return self.cmakeUniversalInstallHelper
    # end
    true
  end
end
