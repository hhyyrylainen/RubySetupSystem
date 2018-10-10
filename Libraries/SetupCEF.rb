# Supported extra options:
#
class CEF < ZipAndCmakeDLDep
  def initialize(args)
    # Windows uses 7z as the zip type
    super("CEF", "CEF", args, zipType: if OS.windows? then :p7zip else :tar end)

    self.HandleStandardCMakeOptions

    # sha1
    @DLHashType = 3

    if !@Version
      # @Version = "3.3497.1836.gb472a8d"
      @Version = "3.3396.1777.g636f29b"
    end

    # Detect platform
    if OS.linux?
      # TODO: also move this to 7z
      @UnZippedName = "cef_binary_#{@Version}_linux64_minimal"
    elsif OS.windows?
      # Needs to patch visual studio 1913 to the supported ones
      @UnZippedName = "cef_binary_#{@Version}_windows64_minimal"
    elsif OS.mac?
      @UnZippedName = "cef_binary_#{@Version}_macosx64_minimal"
    else
      onError "Unknown platform for CEF setup"
    end

    # Version specific hashes
    case @Version
    when "3.3497.1837.g00188c7"
      if OS.linux?
        @DLHash = "9c785c3002092236dac2f45ff1e436a1d44bedc0"
      elsif OS.windows?
        @DLHash = "6a9c87f9bbc00d453aff62f1598bd1296a4dfc8f"
      elsif OS.mac?
        @DLHash = "e30bcab7a0688c51e7c97d5c62ab75f9e6adb59b"
      end         
    when "3.3497.1836.gb472a8d"
      if OS.linux?
        @DLHash = "47c5dd712d7784c7627df53ad2424d7d8f18ed24"
      elsif OS.windows?
        @DLHash = "8d1367ee069b0658dde031ff24fc5946e707f17b"
      elsif OS.mac?
        # This is most likely wrong
        @DLHash = "e30bcab7a0688c51e7c97d5c62ab75f9e6adb59b"
      end
    when "3.3396.1777.g636f29b"
      if OS.linux?
        @DLHash = "fe78f23c64067860a1c963b89e39e6f7ce796074"
      elsif OS.windows?
        @DLHash = "2611ca3dc050c41f6dd4ac51ee1b9b3bb7331290"
      elsif OS.mac?
        @DLHash = "82e27258a604369e0675fd5d8ed340c21b1029d9"
      end
    else
      onError "unknown CEF version: #{@Version}"
    end

    if !@LocalFileName
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

    # Version for packaging
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

      glob = Globber.new "libcef_dll_wrapper.a", File.join(@Folder, "build")
      glob.getResult.each{|f|
        installer.addLibrary f
      }

      FileUtils.mkdir_p File.join(@InstallPath, "bin")
      copyPreserveSymlinks File.join(@Folder, "Release/", "chrome-sandbox"),
                           File.join(@InstallPath, "bin")
      
    elsif OS.windows?
      installer.addLibrary File.join(@Folder, "Release/", "libcef.dll")
      installer.addLibrary File.join(@Folder, "Release/", "chrome_elf.dll")
      installer.addLibrary File.join(@Folder, "Release/", "libEGL.dll")
      installer.addLibrary File.join(@Folder, "Release/", "libGLESv2.dll")
      installer.addLibrary File.join(@Folder, "Release/", "d3dcompiler_47.dll")
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
      ]
    else
      nil
    end
  end
end
