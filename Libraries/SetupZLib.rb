# Supported extra options:
# buildASM: enable assembly implementation (doesn't work without including
#     contrib\masmx64\inffas8664.c in to the build see:
#     https://stackoverflow.com/questions/29505121/cmake-zlib-build-on-windows just set to
#     false and hope it is fast enough)
class ZLib < ZipDLDep
  def initialize(args)
    super("zlib", "zlib", args)

    self.HandleStandardCMakeOptions

    @UnZippedName = "zlib-1.2.11"
    @LocalFileName = "zlib-1.2.11.tar.gz"
    @LocalPath = File.join(CurrentDir, @LocalFileName)
    @DownloadURL = "http://www.zlib.net/zlib-1.2.11.tar.gz"
    @DLHash = "2cb54138a68f3ba32a1610bfae58d46a846ba975421b06181e474f06b75e57cc"

    if args[:buildASM]

      # TODO: architecture
      @Options.push "-DAMD64=ON"
    end
    
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



