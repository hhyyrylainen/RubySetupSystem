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

  def DoClone
    runOpen3("git", "clone", "https://hhyyrylainen@bitbucket.org/hhyyrylainen/leviathan.git",
            "leviathan") == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end  

  def DoSetup
    # TODO: find a way to run the leviathan dependencies here
    # FileUtils.mkdir_p "build"

    # Dir.chdir("build") do
    #   return runCMakeConfigure @Options
    # end
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
  end
end
