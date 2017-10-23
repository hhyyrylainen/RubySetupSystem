# Supported extra options:
#
class SDL < BaseDep
  def initialize(args)
    super("SDL2", "SDL", args)

    self.HandleStandardCMakeOptions
  end

  def DoClone
    runOpen3("hg", "clone", "http://hg.libsdl.org/SDL") == 0
  end

  def DoUpdate
    runOpen3("hg", "pull")
    runOpen3("hg", "update", @Version) == 0
  end  

  def DoSetup
    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      return runCMakeConfigure @Options
    end
  end
  
  def DoCompile

    Dir.chdir("build") do
      
      return runCompiler $compileThreads
      
    end
  end
  
  def DoInstall
    Dir.chdir("build") do
      return self.cmakeUniversalInstallHelper
    end
  end
end
