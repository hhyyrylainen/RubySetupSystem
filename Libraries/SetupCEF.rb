# Supported extra options:
#
class CEF < ZipAndCmakeDLDep
  def initialize(args)
    super("CEF", "CEF", args, zipType: :p7zip)

    self.HandleStandardCMakeOptions

    # TODO: do similar version select as an SetupAngelScript.rb
    @Version = "3.3325.1756.g6d8faa4"

    # sha1
    @DLHashType = 3

    # Detect platform
    if OS.linux?
      # TODO: also move this to 7z
      @UnZippedName = "cef_binary_#{@Version}_linux64_minimal"
      @DLHash = "5077b9580862c6304a34fbe334bc05e4ed1fca55"
    elsif OS.windows?
      # Needs to patch visual studio 1913 to the supported ones
      @UnZippedName = "cef_binary_#{@Version}_windows64_minimal"
      @DownloadURL = "https://boostslair.com/rubysetupsystem/deps/#{@UnZippedName}.7z"
      @DLHash = "6e5efee25057e8b86c347a0e37f3b034376148d872716cc4771eb5f186b86ad0"
      @DLHashType = 2
    elsif OS.mac?
      @UnZippedName = "cef_binary_#{@Version}_macosx64_minimal"
      @DLHash = "96b9d98ee0ee80a1f826588565efc0820070764f"
    else
      onError "Unknown platform for CEF setup"
    end

    if OS.windows?
      @LocalFileName = @UnZippedName + ".7z"
    else
      @LocalFileName = @UnZippedName + ".tar.bz2"
    end
    @LocalPath = File.join(CurrentDir, @LocalFileName)
    if !@DownloadURL
      @DownloadURL = "http://opensource.spotify.com/cefbuilds/#{@LocalFileName}"
    end

    # Windows config options
    if OS.windows?
      @Options.push "-DCEF_RUNTIME_LIBRARY_FLAG=/MD"
      @Options.push "-DUSE_SANDBOX=ON"

      if CMakeBuildType == "RelWithDebInfo"
        @OverrideBuildType = "Release"
      end
    end

    # For packaging
    # not that that is needed for this as this is basically precompiled
    @RepoURL = @DownloadURL
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      
      return [
        "libXcomposite", "libXtst", "libXScrnSaver", "atk"
      ]
      
    end

    if os == "ubuntu"
      
      return [
        "libxcomposite1", "libxtst6", "libxss1", "libatk1.0-0"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end
  
  def getDefaultOptions
    []
  end
  
  def DoInstall
    # There's no install target so we need to manually do it

    # Includes
    copyPreserveSymlinks File.join(@Folder, "include/."), File.join(@InstallPath, "include")
    # Resources
    
    copyPreserveSymlinks File.join(@Folder, "Resources"), File.join(@InstallPath)

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
      installer.addLibrary File.join(@Folder, "Release/", "libcef.dll")
      installer.addLibrary File.join(@Folder, "Release/", "chrome_elf.dll")
      installer.addLibrary File.join(@Folder, "Release/", "libEGL.dll")
      installer.addLibrary File.join(@Folder, "Release/", "libGLESv2.dll")
      installer.addLibrary File.join(@Folder, "Release/", "d3dcompiler_47.dll")
      installer.addLibrary File.join(@Folder, "Release/", "widevinecdmadapter.dll")
      installer.addLibrary File.join(@Folder, "Release/", "cef_sandbox.lib")
      installer.addLibrary File.join(@Folder, "Release/", "libcef.lib")

      glob = Globber.new "libcef_dll_wrapper.lib", File.join(@Folder, "build")
      glob.getResult.each{|f|
        installer.addLibrary f
      }
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
      [
        "cefextrablobs",
        "Resources",
        "swiftshader",

        "include/base",
        "include/capi",
        "include/internal",
        "include/test",
        "include/views",
        "include/wrapper",

        *Dir.glob([@InstallPath + "/include/cef_*.h"]).map{|i| i.sub(@InstallPath + "/", "")},

        # sandbox doesn't work so we don't include it
        "lib/libcef.lib",
        "lib/libcef_dll_wrapper.lib",

        "lib/libcef.dll",
        "lib/chrome_elf.dll",
        "lib/libEGL.dll",
        "lib/libGLESv2.dll",
        "lib/d3dcompiler_47.dll",
        "lib/widevinecdmadapter.dll",
      ]
    else
      nil
    end
  end
end
