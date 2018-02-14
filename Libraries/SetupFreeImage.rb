# Supported extra options:
#
class FreeImage < StandardCMakeDep
  def initialize(args)
    super("FreeImage", "FreeImage", args)

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/hhyyrylainen/FreeImage.git"
    end

    @BranchEpoch = 2
  end

  def DoClone
    runOpen3("git", "clone", @RepoURL) == 0
  end

  def DoUpdate
    self.standardGitUpdate
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

        "include/FreeImage.h",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end
