# Supported extra options:
#
class FreeType < ZipDLDep
  def initialize(args)
    super("FreeType", "freetype", args)

    self.HandleStandardCMakeOptions

    @UnZippedName = "freetype-2.8"
    @LocalFileName = "freetype-2.8.tar.gz"
    @LocalPath = File.join(CurrentDir, @LocalFileName)
    @DownloadURL = "http://download.savannah.gnu.org/releases/freetype/freetype-2.8.tar.gz"
    @DLHash = "c02da3ab5c94c696b5800e16181c734597d55bbea9f88b04d0d99a1c075ea504"
    
  end

  def getDefaultOptions
    [
      # Shared prints this error with msvc: Building shared libraries on Windows needs MinGW
      # "-DBUILD_SHARED_LIBS=ON",
    ]
  end

  def DoSetup
    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      return runCMakeConfigure @Options
    end
  end
  
  def DoCompile

    Dir.chdir("build") do
      
      return runCompiler $compileThreads, winBothConfigurations: false
    end
  end
  
  def DoInstall

    Dir.chdir("build") do
      return self.cmakeUniversalInstallHelper winBothConfigurations: false
    end
  end
end
