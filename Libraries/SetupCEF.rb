# Supported extra options:
#
class CEF < ZipAndCmakeDLDep
  def initialize(args)
    super("CEF", "CEF", args)

    self.HandleStandardCMakeOptions

    @Version = "3.3325.1756.g6d8faa4"

    # sha1
    @DLHashType = 3

    # Detect platform
    if OS.linux?
      @UnZippedName = "cef_binary_#{@Version}_linux64_minimal"
      @DLHash = "5077b9580862c6304a34fbe334bc05e4ed1fca55"
    elsif OS.windows?
      @UnZippedName = "cef_binary_#{@Version}_windows64_minimal"
      @DLHash = "2cac794d9e1bdb0ab8cf5a35f738eb7490eff640"
    elsif OS.mac?
      @UnZippedName = "cef_binary_#{@Version}_macosx64_minimal"
      @DLHash = "96b9d98ee0ee80a1f826588565efc0820070764f"
    else
      onError "Unknown platform for CEF setup"
    end

    @LocalFileName = @UnZippedName + ".tar.bz2"
    @LocalPath = File.join(CurrentDir, @LocalFileName)
    @DownloadURL = "http://opensource.spotify.com/cefbuilds/#{@LocalFileName}"

    # For packaging
    # not that that is needed for this as this is basically precompiled
    @RepoURL = @DownloadURL
  end

  def getDefaultOptions
    []
  end
  
  def DoInstall
    # There's no install target so we need to manually do it

    # Includes
    copyPreserveSymlinks File.join(@Folder, "include/."), File.join(@InstallPath, "include")
    # Resources
    
    copyPreserveSymlinks File.join(@Folder, "Resources"), File.join(@InstallPath, "Resources")

    # Extra libs
    copyPreserveSymlinks File.join(@Folder, "Release/swiftshader"), @InstallPath

    # And blobs
    FileUtils.mkdir_p File.join(@InstallPath, "cefextrablobs")
    Dir.glob(File.join(@Folder, "Release/*.bin")).each{|f|
      copyPreserveSymlinks f, File.join(@InstallPath, "cefextrablobs/")
    }

    # And finally the libraries
    installer = CustomInstaller.new(@InstallPath,
                                    File.join(@Folder, "Release"))
    
    # Libraries
    if OS.linux?
      installer.addLibrary File.join(@Folder, "Release/", "libcef.so")
      installer.addLibrary File.join(@Folder, "Release/", "libEGL.so")
      installer.addLibrary File.join(@Folder, "Release/", "libGLESv2.so")
      installer.addLibrary File.join(@Folder, "Release/", "libwidevinecdmadapter.so")

      glob = Globber.new "libcef_dll_wrapper.a", File.join(@Folder, "build")
      glob.getResult.each{|f|
        installer.addLibrary f
      }
      
    elsif OS.windows?
      onError "TODO: files"
    elsif OS.mac?
      onError "TODO: files"
    else
      onError "Unknown platform for CEF install"
    end

    installer.run
  end  

  def getInstalledFiles
    # This is only partly precompiled
    if OS.windows?
      nil
    else
      nil
    end
  end
end
