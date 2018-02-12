# Supported extra options:
#
class FreeImage < BaseDep
  def initialize(args)
    super("FreeImage", "FreeImage", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/hhyyrylainen/FreeImage.git"
    end
  end

  def DoClone
    runOpen3("git", "clone", @RepoURL) == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  def DoSetup
    if OS.windows?
      if !File.exists?(File.join(@Folder, "FreeImage.2017.sln"))
        return false
      end

      # Not needed with our own version of the library to check for toolset
      return true
    else
      File.exists?(File.join(@Folder, "Makefile"))
    end
  end
  
  def DoCompile

    if OS.windows?

      # Doesn't use TC.isToolSetClang always uses the default msvc
      # toolset, hopefully works
      runVSCompiler($compileThreads, configuration: "Release", platform: "x64",
                    project: "FreeImage.2017.sln")
    else

      onError "TODO: makefile compile"
    end
  end
  
  def DoInstall

    # Copy files to the install target folder
    # TODO: architecture
    installer = CustomInstaller.new(@InstallPath,
                                    File.join(@Folder, "Dist/x64"))
    
    # First header files and libs
    installer.addInclude(File.join(@Folder, "Dist/x64", "FreeImage.h"))
    
    # The library
    if OS.linux?

      installer.addLibrary File.join(@Folder, "Dist/x64", "FreeImage.so")
      
    elsif OS.windows?
      installer.addLibrary File.join(@Folder, "Dist/x64", "FreeImage.lib")
      installer.addLibrary File.join(@Folder, "Dist/x64", "FreeImage.dll")
    else
      onError "Unkown OS"
    end
    
    installer.run
  end

  def getInstalledFiles
    if OS.windows?
      [
        "lib/FreeImage.lib",
        "lib/FreeImage.dll",

        "bin/zlib.dll",

        "include/FreeImage.h",
      ]
    else
      onError "TODO: linux file list"
    end
  end
end
