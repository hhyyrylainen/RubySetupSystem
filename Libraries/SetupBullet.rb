# Supported extra options:
# disableGraphicalBenchmark skips building extra part
# disableCPUDemos Skip building a lot of the demos
# disableGLUT don't use GLUT on windows
# buildPyBullet If you want to build python bindings
# buildSocket Build networked parts
# buildTests Build tests
class Bullet < StandardCMakeDep
  def initialize(args)
    super("Bullet", "bullet3", args)

    if args[:disableGraphicalBenchmark]
      @Options.push "-DUSE_GRAPHICAL_BENCHMARK=OFF"
    end

    if args[:disableCPUDemos]
      @Options.push "-DBUILD_CPU_DEMOS=OFF"
    end

    if args[:disableGLUT]
      @Options.push "-DUSE_GLUT=OFF"
    end

    if args[:buildPyBullet]
      @Options.push "-DBUILD_PYBULLET=ON"
    else
      @Options.push "-DBUILD_PYBULLET=OFF"
    end

    if args[:disableDemos]
      @Options.push "-DBUILD_OPENGL3_DEMOS=OFF"
      @Options.push "-DBUILD_BULLET2_DEMOS=OFF"
    end

    if args[:buildSocket]
      @Options.push "-DBUILD_ENET=ON"
      @Options.push "-DBUILD_CLSOCKET=ON"
    else
      @Options.push "-DBUILD_ENET=OFF"
      @Options.push "-DBUILD_CLSOCKET=OFF"
    end

    if args[:buildTests]
      @Options.push "-DBUILD_UNIT_TESTS=ON"
    else
      @Options.push "-DBUILD_UNIT_TESTS=OFF"
    end    

    if args[:shared]
      @Options.push "-DBUILD_SHARED_LIBS=ON"
    else
      @Options.push "-DBUILD_SHARED_LIBS=OFF"
    end

    # Auto Windows options
    if OS.windows?
      @Options.push "-DUSE_MSVC_RUNTIME_LIBRARY_DLL=ON"
    end

    self.HandleStandardCMakeOptions

    if !@RepoURL
      @RepoURL = "https://github.com/bulletphysics/bullet3.git"
    end
  end

  def DoClone
    runSystemSafe("git", "clone", @RepoURL) == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  # TODO: debug suffix for builds
  def translateBuildType(type)
    if type == "RelWithDebInfo"
      return "_RelWithDebugInfo"
    elsif type == "MinSizeRel"
      return "_MinimumSizeRelease"
    elsif type == "Release"
      return ""
    elsif type == "Debug"
      return "_Debug"
    else
      return type
    end
  end

  def DoInstall
    if OS.windows?
      # There isn't an install target on Windows
      # so copy manually
      # Copy files to the install target folder
      
      base = File.join(@Folder, "build/lib/#{CMakeBuildType}/")
      target = File.join @InstallPath, "lib/"

      FileUtils.mkdir_p target

      type = translateBuildType CMakeBuildType
      
      # libraries
      # TODO: this needs fixing for debug vs. release mode
      [
        "Bullet2FileLoader", "Bullet3Collision", "Bullet3Common", "Bullet3Dynamics",
        "Bullet3Geometry", "Bullet3OpenCL_clew", "BulletCollision", "BulletDynamics",
        "BulletFileLoader", "BulletInverseDynamicsUtils", "BulletInverseDynamics",
        "BulletRobotics", "BulletSoftBody", "BulletWorldImporter", "BulletXmlWorldImporter",
        "ConvexDecomposition", "GIMPACTUtils", "HACD", "LinearMath"
      ].each{|item|
        FileUtils.cp base + "#{item}#{type}.lib", target + item + ".lib"
      }
      
      # include files
      installer = CustomInstaller.new(@InstallPath, File.join(@Folder, "src"))
      installer.setIncludePrefix "bullet"

      Dir[File.join(@Folder, "src", "**/{*.h,*.hpp}")].each{|file|
        installer.addInclude(file)
      }
      
      installer.run

      # extras
      installer = CustomInstaller.new(@InstallPath, File.join(@Folder, "Extras"))
      installer.setIncludePrefix "bullet"

      Dir[File.join(@Folder, "Extras", "**/{*.h,*.hpp}")].each{|file|
        installer.addInclude(file)
      }
      
      installer.run
    else
      super
    end
  end

  def getInstalledFiles
    if OS.windows?
      [
        "lib/Bullet2FileLoader.lib",
        "lib/Bullet3Collision.lib",
        "lib/Bullet3Common.lib",
        "lib/Bullet3Dynamics.lib",
        "lib/Bullet3Geometry.lib",
        "lib/Bullet3OpenCL_clew.lib",
        "lib/BulletCollision.lib",
        "lib/BulletDynamics.lib",
        "lib/BulletFileLoader.lib",
        "lib/BulletInverseDynamicsUtils.lib",
        "lib/BulletInverseDynamics.lib",
        "lib/BulletRobotics.lib",
        "lib/BulletSoftBody.lib",
        "lib/BulletWorldImporter.lib",
        "lib/BulletXmlWorldImporter.lib",
        "lib/ConvexDecomposition.lib",
        "lib/GIMPACTUtils.lib",
        "lib/HACD.lib",
        "lib/LinearMath.lib",
        "include/bullet",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end


