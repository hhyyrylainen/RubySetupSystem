# Supported extra options:
# :enablePIC => enable -fPIC when building
# :buildShared => only shared versions of the libraries are built
# :enableSmall => optimize for size
# :noStrip => disable stripping
class FFMPEG < BaseDep
  def initialize(args)

    super("FFmpeg", "ffmpeg", args)

    if @InstallPath

      @Options.push("--prefix=#{@InstallPath}")
      
    end

    if args[:enablePIC]
      @Options.push "--enable-pic"
      @Options.push "--extra-ldexeflags=-pie"
    end

    if args[:buildShared]

      @Options.push "--disable-static"
      @Options.push "--enable-shared"
      
    end

    if args[:enableSmall]
      @Options.push "--enable-small"
    end

    if args[:noStrip]
      @Options.push "--disable-stripping"
    end

    if OS.windows?

      # Can't make configure use anything else except gcc, so I guess
      # we have to compile with msvc and hope binaries are compatible
      @UseClangIfSet = false
      
      if TC.is_a? WindowsMSVC

        # If VS is using clang toolset don't actually use msvc as a toolchain here
        if self.getIsClang
          puts "#{@Name} using clang (in msvc) toolchain"

          @Clang = WindowsClang.new

          # We rely on CXX and CC environment variables to tell configure to use clang
        else

          puts "#{@Name} using msvc toolchain"
          @Options.push "--toolchain=msvc"

          # This doesn't understand cygwin paths
          # so if we don't use --toolchain=msvc we can't use this
          @YasmFolder = File.expand_path(File.join @Folder, "../", "ffmpeg-win-tools")
        end

        # Set build type
        @Options.push "--arch=x86_64"
        puts "#{@Name} using 64-bit build"
      else
        onError "this needs verification if this works at all"
        @Options.push "--toolchain=gcc"        
      end
    end

    if !@RepoURL
      @RepoURL = "https://github.com/FFmpeg/FFmpeg.git"
    end
    
    self.clearEmptyOptions
    
  end

  def getDefaultOptions
    [
      "--disable-doc",
      # This is useful to comment when testing which components need to
      # be compiled
      "--disable-programs"
    ]
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      
      return [
        "autoconf", "automake", "bzip2", "cmake", "freetype-devel", "gcc", "gcc-c++",
        "git", "libtool", "make", "mercurial", "nasm", "pkgconfig", "zlib-devel", "yasm"
      ]
      
    end

    if os == "ubuntu"
      
      return [
        "autoconf", "automake", "build-essential",
        "libass-dev", "libfreetype6-dev", "libsdl2-dev", "libtheora-dev",
        "libtool", "libva-dev", "libvdpau-dev", "libvorbis-dev", "libxcb1-dev",
        "libxcb-shm0-dev", "libxcb-xfixes0-dev", "pkg-config", "texinfo",
        "zlib1g-dev"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end

  def DoClone
    runOpen3("git", "clone", @RepoURL, "ffmpeg") == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  # Helper for windows clang compiling
  def setCXXEnv
    # Could store and restore these...
    @Clang.setupEnv    
  end

  # Helper for windows clang compiling
  def unsetCXXEnv
    @Clang.unsetEnv
  end

  def getIsClang
    TC.isToolSetClang && @UseClangIfSet
  end

  def getModifiedPaths
    if !self.getIsClang
      [TC.VS.getVSLinkerFolder, @YasmFolder]
    else
      [TC.VS.getVSLinkerFolder]
    end
  end

  def DoSetup

    if OS.windows?

      # Check that cygwin is properly installed
      requireCMD "sh", "Please make sure you have installed 'bash' with cygwin"
      requireCMD "pr", "Please make sure you have installed 'coreutils' with cygwin"
      
      someFFMPEGMakeFile = "common.mak"
      
      # Check line endings
      if getFileLineEndings(someFFMPEGMakeFile) != "\n"
        warning "ffmpeg makefiles have non-unix line endings. Fixing."
        
        gitFixCRLFEndings someFFMPEGMakeFile    
      end
      
      # YASM assembler is required, so download that
      if self.getIsClang
        yasmExecutable = File.join @YasmFolder, "yasm.exe"
        
        if !File.exists? yasmExecutable
          # We need to download it
          FileUtils.mkdir_p @YasmFolder
          
          downloadURLIfTargetIsMissing(
            "http://www.tortall.net/projects/yasm/releases/yasm-1.3.0-win64.exe",
            yasmExecutable, "f61a039125f3650b03e523796b9ed7094c1c89d3a45d160eac01eba2ffe8f2f6")
          
          onError "yasm tool dl failed" if !File.exists? yasmExecutable
          
        end
      else
        # When using clang we need to have it from cygwin
        yasmExecutable = which "yasm"

        if !yasmExecutable || yasmExecutable !~ /cygwin64/i
          onError "yasm needs to be installed in cygwin. But it isn't. Found path: " +
                  "'#{yasmExecutable}'"
        end
      end

      path = Dir.pwd

      if self.getIsClang
        setCXXEnv
      end
      
      runWithModifiedPath(self.getModifiedPaths, true){
        Open3.popen2e(*[TC.VS.runVSVarsAll, "&&", "cd", path, "&&", 
                        "sh", "./configure", @Options].flatten){
          |stdin, out, wait_thr|
          
          out.each {|line|
            puts line
          }
          
          exit_status = wait_thr.value          
          return exit_status == 0
        }
      }
      
    else

      return runOpen3("./configure", *@Options) == 0
    end
  end
  
  def DoCompile
    if OS.windows?

      path = Dir.pwd

      if self.getIsClang
        setCXXEnv
      end

      requireCMD "make", "Please make sure you have installed 'make' with cygwin"
      runWithModifiedPath(self.getModifiedPaths, true){
        Open3.popen2e(*[TC.VS.runVSVarsAll, "&&", "cd", path, "&&", "make", "-j", 
                        $compileThreads.to_s].flatten) {|stdin, out, wait_thr|
          
          out.each {|line|
            puts line
          }
          
          exit_status = wait_thr.value
          return exit_status == 0
        }
      }
    else

      return TC.runCompiler
    end
  end

  def DoInstall

    if OS.windows?
      
      if shouldUseSudo(@InstallSudo)
        warning "#{Name} sudo install does nothing extra on windows"      
      end

      path = Dir.pwd

      if self.getIsClang
        setCXXEnv
      end
      
      runWithModifiedPath(self.getModifiedPaths, true){
        Open3.popen2e(*[TC.VS.runVSVarsAll, "&&", "cd", path, "&&", "make",
                        "install"].flatten){
          |stdin, out, wait_thr|
          
          out.each {|line|
            puts line
          }
          
          exit_status = wait_thr.value

          # We unset just once at the end
          if self.getIsClang
            unsetCXXEnv
          end

          if exit_status == 0
            # Check that some file exists
            someFile = File.join(@InstallPath, "bin/avformat.lib")

            if !File.exists? someFile
              onError "#{@Name} building / installing failed (#{someFile} doesn't exist). " +
                      "Make sure there are no errors above from #{@Name} configure or build"
            end
          end
          
          return exit_status == 0
        }
      }
    else

      return self.linuxMakeInstallHelper
    end
  end

  def getInstalledFiles
    if OS.windows?
      [
        "lib/avcodec-57.def",
        "lib/avformat-57.def",
        "lib/avutil-55.def",
        "lib/swresample-2.def",
        "lib/swscale-4.def",

        "bin/avcodec.lib",
        "bin/avformat.lib",
        "bin/avutil.lib",
        "bin/swresample.lib",
        "bin/swscale.lib",

        "bin/avcodec-57.dll",
        "bin/avformat-57.dll",
        "bin/avutil-55.dll",
        "bin/swresample-2.dll",
        "bin/swscale-4.dll",

        "include/libavcodec",
        "include/libavformat",
        "include/libavutil",
        "include/libswresample",
        "include/libswscale",

      ]
    else
      onError "TODO: linux file list"
    end
  end
end
