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

  def getInstalledFiles
    if OS.windows?
      [
        "lib/Newton.dll",
        "lib/Newton.lib",
        "include/Newton.h",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end
end


