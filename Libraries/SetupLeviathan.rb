# Supported extra options:
#
# Note: the current leviathan versions aren't meant to be installed so
# the install path is mostly ignored
class Leviathan < BaseDep
  def initialize(args)
    super("Leviathan", "leviathan", args)

    self.HandleStandardCMakeOptions
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
    runOpen3("git", "clone", "https://bitbucket.org/hhyyrylainen/leviathan.git",
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
    # Leviathan needs sometimes to get input from the user so we need to run with system here
    cmd = "ruby Setup.rb"
    
    if !$preCompiled.nil?
      if $preCompiled == false
        cmd += " --no-precompiled"
      elsif $preCompiled == true
        cmd += " --precompiled"
      end
    end
    
    system(cmd)
    $?.exitstatus == 0
  end
  
  def DoInstall
    # Installation not used
    
    # Dir.chdir("build") do
    #   return self.cmakeUniversalInstallHelper
    # end
    true
  end
end
