# Supported extra options:
# :enablePIC => enable -fPIC when building
# :buildShared => only shared versions of the libraries are built
# :enableSmall => optimize for size
# :noStrip => disable stripping
class FFMPEG < BaseDep
  def initialize(args)

    super("FFmpeg", "ffmpeg", args)

    if @InstallPath

      @Options.push(if OS.windows? then "--prefix=#{@InstallPath}" else 
                     "--prefix='#{@InstallPath}'" end)
      
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
      @Options.push "--toolchain=msvc"
      @YasmFolder = File.expand_path(File.join @Folder, "../", "ffmpeg-win-tools")
      puts "#{@Name} using msvc toolchain"
      # This may or may not be required as the used compiler is chosen manually by
      # the user by running 'vcvarsall.bat amd64'
      @Options.push "--arch=x86_64"
      puts "#{@Name} using 64-bit build"
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
    runOpen3("git", "clone", "https://github.com/FFmpeg/FFmpeg.git", "ffmpeg") == 0
  end

  def DoUpdate
    self.standardGitUpdate
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
      yasmExecutable = File.join @YasmFolder, "yasm.exe"
      
      if !File.exists? yasmExecutable
        # We need to download it
        FileUtils.mkdir_p @YasmFolder
        
        downloadURLIfTargetIsMissing(
          "http://www.tortall.net/projects/yasm/releases/yasm-1.3.0-win64.exe",
          yasmExecutable)
        
        onError "yasm tool dl failed" if !File.exists? yasmExecutable
        
      end
      
      runWithModifiedPath([getVSLinkerFolder, @YasmFolder], true){
        Open3.popen2e(*[runVSVarsAll, "&&", "sh", "./configure", @Options].flatten){
          |stdin, out, wait_thr|
          
          out.each {|line|
            puts line
          }
          
          exit_status = wait_thr.value
          return exit_status == 0
        }
      }
      
    else

      return runOpen3("./configure", @Options) == 0
    end
  end
  
  def DoCompile
    if OS.windows?

      requireCMD "make", "Please make sure you have installed 'make' with cygwin"
      runWithModifiedPath([getVSLinkerFolder, @YasmFolder], true){
        Open3.popen2e(*[runVSVarsAll, "&&", "make", "-j", 
                        CompileThreads.to_s].flatten) {|stdin, out, wait_thr|
          
          out.each {|line|
            puts " " + line
          }
          
          exit_status = wait_thr.value
          return exit_status == 0
        }
      }
    else

      runCompiler CompileThreads
      return $?.exitstatus == 0
    end
  end

  def DoInstall

    if OS.windows?
      
      if shouldUseSudo(@InstallSudo)
        warning "#{Name} sudo install doesn nothing extra on windows"      
      end
      
      runWithModifiedPath([getVSLinkerFolder, @YasmFolder], true){
        Open3.popen2e(*[runVSVarsAll, "&&", "make", "install"].flatten){
          |stdin, out, wait_thr|
          
          out.each {|line|
            puts " " + line
          }
          
          exit_status = wait_thr.value
          return exit_status == 0
        }
      }
    else

      return self.linuxMakeInstallHelper
    end
  end
end
