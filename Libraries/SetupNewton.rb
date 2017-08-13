# Supported extra options:
# :disableDemos => disable demo programs
class Newton < BaseDep
  def initialize(args)
    super("Newton Dynamics", "newton-dynamics", args)

    if args[:disableDemos]

      @Options.push "-DNEWTON_DEMOS_SANDBOX=OFF"
    end

  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      return [
        "tinyxml-devel"
      ]
    end

    if os == "ubuntu"
      return [
        "libtinyxml-dev"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end  

  def DoClone
    runOpen3("git", "clone",
             "https://github.com/MADEAPPS/newton-dynamics.git") == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  def DoSetup
    
    if OS.windows?
      # TODO: vs version select
      return File.exist? "packages/projects/visualStudio_2015_dll/build.sln"
    else
      FileUtils.mkdir_p "build"

      Dir.chdir("build") do
        
        return runCMakeConfigure @Options
      end
    end      
  end
  
  def DoCompile
    if OS.windows?
      
      return runVSCompiler(CompileThreads,
                           project: "packages/projects/visualStudio_2015_dll/build.sln",
                           configuration: "release",
                           platform: "x64")
      
      return $?.exitstatus == 0
    else
      Dir.chdir("build") do
        
        return runCompiler CompileThreads
        
      end
    end
  end
  
  def DoInstall
    
    # Copy files to the install target folder
    baseSourcePath = File.join(@Folder, "coreLibrary_300/source")
    
    installer = CustomInstaller.new(@InstallPath, baseSourcePath)
    
    installer.addInclude(Globber.new("Newton.h", baseSourcePath).getResult)
    
    if OS.linux?

      installer.addLibrary(Globber.new("libNewton.so",
                                       File.join(@Folder, "build/lib")).getResult)

    elsif OS.windows?

      installer.addLibrary(
        Globber.new("newton.dll", File.join(@Folder, "coreLibrary_300/projects/windows")).
          getResult)


      installer.addLibrary(
        Globber.new("newton.lib", File.join(@Folder, "coreLibrary_300/projects/windows")).
          getResult)
    else
      onError "Unkown os"
    end

    installer.run
    
    true
  end
end
