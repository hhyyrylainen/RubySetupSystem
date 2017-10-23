# Will set OGRE_HOME when Enable is called
# Supported extra options:
# TODO: all the render system and component flags
#
# noSamples: disables the v2 samples
# Windows: these other libraries need to be installed before:
# FreeType
class Ogre < BaseDep
  def initialize(args)
    super("Ogre", "ogre", args)

    self.HandleStandardCMakeOptions

    if args[:noSamples]

      @Options.push "-DOGRE_BUILD_SAMPLES2=OFF"
    end
    
  end

  def getDefaultOptions
    [
      "-DOGRE_BUILD_RENDERSYSTEM_GL3PLUS=ON",
      "-DOGRE_BUILD_COMPONENT_OVERLAY=OFF",
      "-DOGRE_BUILD_COMPONENT_PAGING=OFF",
      "-DOGRE_BUILD_COMPONENT_PROPERTY=OFF",
      "-DOGRE_BUILD_COMPONENT_TERRAIN=OFF",
      "-DOGRE_BUILD_COMPONENT_VOLUME=OFF",
      "-DOGRE_BUILD_PLUGIN_BSP=OFF",
      "-DOGRE_BUILD_PLUGIN_CG=OFF",
      "-DOGRE_BUILD_SAMPLES=OFF"
    ]
  end

  def depsList
    os = getLinuxOS

    if os == "fedora" || os == "centos" || os == "rhel"
      
      return [
        "gcc-c++", "libXaw-devel", "freetype-devel", "freeimage-devel", "zziplib-devel",
        "cmake", "ois-devel", "libatomic"
      ]
      
    end

    if os == "ubuntu"
      
      return [
        "build-essential", "automake", "libtool", "libfreetype6-dev", "libfreeimage-dev",
        "libzzip-dev", "libxrandr-dev", "libxaw7-dev", "freeglut3-dev", "libgl1-mesa-dev",
        "libglu1-mesa-dev", "libois-dev", "libatomic1"
      ]
    end

    if os == "arch"
      return [
        "freeimage", "freetype2", "libxaw", "libxrandr", "mesa", "ois", "zziplib", "cmake",
        "gcc"
      ]
    end
    
    onError "#{@name} unknown packages for os: #{os}"

  end

  def installPrerequisites

    installDepsList depsList
    
  end

  def RequiresClone
    return (not File.exist? @Folder)
  end
  
  def DoClone
    runOpen3("hg", "clone", "https://bitbucket.org/sinbad/ogre") == 0
  end

  def DoUpdate
    
    runOpen3 "hg", "pull"
    runOpen3("hg", "update", @Version) == 0
  end

  def DoSetup
    
    # # Dependencies compile
    # additionalCMake = []
    
    # if OS.windows?
    #   Dir.chdir("Dependencies") do

    #     # there was a no build sdl2 here...
    #     runOpen3Checked "cmake", "."

    #     if !runVSCompiler $compileThreads

    #       onError "Failed to compile Ogre dependencies "
    #     end

    #     onError "check can this actually be ran automatically"
    #     info "Please open the solution SDL2 in Release and x64: "+
    #          "#{@Folder}/Dependencies/src/SDL2/VisualC/SDL_VS2013.sln"

    #     openVSSolutionIfAutoOpen "#{@Folder}/Dependencies/src/SDL2/VisualC/SDL_VS2013.sln"

    #     onError "TODO: verify that this works"
    #     additionalCMake.push("-DSDL2MAIN_LIBRARY=..\SDL2\VisualC\Win32\Debug\SDL2main.lib ",
    #                          "-DSD2_INCLUDE_DIR=..\SDL2\include",
    #                          "-DSDL2_LIBRARY_TEMP=..\SDL2\VisualC\Win32\Debug\SDL2.lib")
        
    #   end
    # end
    
    FileUtils.mkdir_p "build"
    
    Dir.chdir("build") do

      return runCMakeConfigure @Options #+ additionalCMake 
    end
    
  end
  
  def DoCompile
    Dir.chdir("build") do

      return runCompiler $compileThreads
    end
  end
  
  def DoInstall

    Dir.chdir("build") do

      if not self.cmakeUniversalInstallHelper
        return false
      end
      
    end

    true
  end

  def Enable
    ENV["OGRE_HOME"] = File.join @InstallPath
  end
end

