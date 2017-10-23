# Supported extra options:
#
class FreeImage < BaseDep
  def initialize(args)
    super("FreeImage", "FreeImage", args)

    self.HandleStandardCMakeOptions    
  end

  def DoClone
    runOpen3("git", "clone", "https://github.com/hhyyrylainen/FreeImage.git") == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  def DoSetup
    if OS.windows?
      if !File.exists?(File.join(@Folder, "FreeImage.2015.sln"))
        return false
      end

      # Not needed with our own version of the library
      # Error about old toolset
      # verifyVSProjectPlatformToolset(File.join(@Folder, "FreeImage.2013.vcxproj"),
      #                               /.*/, "v140")
      return true
    else
      File.exists?(File.join(@Folder, "Makefile"))
    end
  end
  
  def DoCompile

    if OS.windows?

      runVSCompiler($compileThreads, configuration: "Release", platform: "x64",
                    project: "FreeImage.2015.vcxproj")
    else

      onError "TODO: make file compile"
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
end
