# Will set OGRE_HOME when Enable is called
# Supported extra options:
# TODO: all the render system and component flags
#
# noSamples: disables the v2 samples
# Windows: these other libraries need to be installed before:
# FreeType ZLib FreeImage
class Ogre < StandardCMakeDep
  def initialize(args)
    super("Ogre", "ogre", args)

    self.HandleStandardCMakeOptions

    if args[:noSamples]

      @Options.push "-DOGRE_BUILD_SAMPLES2=OFF"
    end

    if !@RepoURL
      @RepoURL = "https://bitbucket.org/sinbad/ogre"
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
    runOpen3("hg", "clone", @RepoURL) == 0
  end

  def DoUpdate
    
    runOpen3 "hg", "pull"
    runOpen3("hg", "update", @Version) == 0
  end

  def getInstalledFiles
    if OS.windows?
      [
        "lib/RelWithDebInfo/opt/Plugin_ParticleFX.lib",
        "lib/RelWithDebInfo/opt/RenderSystem_Direct3D11.lib",
        "lib/RelWithDebInfo/opt/RenderSystem_GL3Plus.lib",
        "lib/RelWithDebInfo/OgreHlmsPbs.lib",
        "lib/RelWithDebInfo/OgreHlmsPbsMobile.lib",
        "lib/RelWithDebInfo/OgreHlmsUnlit.lib",
        "lib/RelWithDebInfo/OgreHlmsUnlitMobile.lib",
        "lib/RelWithDebInfo/OgreMain.lib",
        "lib/RelWithDebInfo/OgreMeshLodGenerator.lib",

        "bin/relwithdebinfo/OgreHlmsPbs.dll",
        "bin/relwithdebinfo/OgreHlmsPbsMobile.dll",
        "bin/relwithdebinfo/OgreHlmsUnlit.dll",
        "bin/relwithdebinfo/OgreHlmsUnlitMobile.dll",
        "bin/relwithdebinfo/OgreMain.dll",
        "bin/relwithdebinfo/OgreMeshLodGenerator.dll",
        "bin/relwithdebinfo/Plugin_ParticleFX.dll",
        "bin/relwithdebinfo/RenderSystem_Direct3D11.dll",
        "bin/relwithdebinfo/RenderSystem_GL3Plus.dll",

        "include/OGRE",
        "Docs/License.html",

        # Might as well include the tool
        "bin/relwithdebinfo/OgreMeshTool.exe",
      ]
    else
      #onError "TODO: linux file list"
      nil
    end
  end

  # This may be needed for CEGUI on windows
  def Enable
    ENV["OGRE_HOME"] = File.join @InstallPath
  end
end

