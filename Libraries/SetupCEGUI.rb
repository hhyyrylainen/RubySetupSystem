# Ogre must be installed for this to work, or the Ogre location needs to be provided
# through extra options
# Supported extra options:
# TODO: component configuration
class CEGUI < BaseDep
  def initialize(args)
    super("CEGUI", "cegui", args)

    if @InstallPath
      @Options.push "-DCMAKE_INSTALL_PREFIX=#{@InstallPath}"
    end

    if @PythonBindings
      @Options.push "-DCEGUI_BUILD_PYTHON_MODULES=ON"
    else
      @Options.push "-DCEGUI_BUILD_PYTHON_MODULES=OFF"
    end

    if OS.windows?
      onError "todo: subdependency"
    end
  end

  def getDefaultOptions
    [
      # Use UTF-8 strings with CEGUI (string class 1)
      "-DCEGUI_STRING_CLASS=1",
      "-DCEGUI_BUILD_APPLICATION_TEMPLATES=OFF",
      "-DCEGUI_SAMPLES_ENABLED=OFF",
      "-DCEGUI_BUILD_RENDERER_OGRE=ON",
      "-DCEGUI_BUILD_RENDERER_OPENGL=OFF",
      "-DCEGUI_BUILD_RENDERER_OPENGL3=OFF",
    ]
  end

  def DoClone
    requireCMD "hg"
    system "hg clone https://bitbucket.org/cegui/cegui"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "hg pull"
    system "hg update #{@Version}"
    $?.exitstatus == 0
  end

  def DoSetup

    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      
      return runCMakeConfigure @Options
    end
  end
  
  def DoCompile
    Dir.chdir("build") do
      return runCompiler CompileThreads 
    end
  end
  
  def DoInstall

    Dir.chdir("build") do
      return self.cmakeUniversalInstallHelper
    end
  end
end


#
# Sub-dependency for windows builds
#

# Windows only CEGUI dependencies
# TODO: fix this
class CEGUIDependencies < BaseDep
  def initialize(args)
    super("CEGUI Dependencies", "cegui-dependencies", args)

    if not OS.windows?
      onError "CEGUIDependencies are Windows-only, they aren't " +
              "required on other platforms"
    end
  end

  def DoClone
    requireCMD "hg"
    system "hg clone https://bitbucket.org/cegui/cegui-dependencies"
    $?.exitstatus == 0
  end

  def DoUpdate
    system "hg pull"
    system "hg update default"
    $?.exitstatus == 0
  end

  def DoSetup

    FileUtils.mkdir_p "build"

    Dir.chdir("build") do
      return runCMakeConfigure @Options
    end
  end
  
  def DoCompile

    Dir.chdir("build") do

      if not runVSCompiler CompileThreads, configuration: "Debug"

        return false
      end
      
      if not runVSCompiler CompileThreads, configuration: "RelWithDebInfo"
        return false
      end
    end
    true
  end
  
  def DoInstall

    FileUtils.copy_entry File.join(@Folder, "build", "dependencies"),
                         # TODO: this needs to be set by the CEGUI build object
                         File.join(CurrentDir, "cegui", "dependencies")
    true
  end
end

